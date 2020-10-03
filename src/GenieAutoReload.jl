module GenieAutoReload

using Revise
using Genie, Genie.Router, Genie.WebChannels
using Distributed, Logging

Genie.config.websockets_server = true

const WEBCHANNEL_NAME = "autoreload"
const GENIE_AUTORELOAD = true
const WATCHED_FOLDERS = String[]
const WATCHED_EXTENSIONS = String["jl", "html", "md", "js", "css"]
const SCRIPT_URI = "/js/plugins/autoreload.js"

function collect_watched_files(folders::Vector{String} = String[]) :: Vector{String}
  result = String[]

  for f in folders
    try
      push!(result, Genie.Util.walk_dir(f, only_extensions = WATCHED_EXTENSIONS)...)
    catch ex
      @error ex
    end
  end

  result
end

function watch()
  @info "Watching $WATCHED_FOLDERS"

  entr(collect_watched_files(WATCHED_FOLDERS); all = true, postpone = true) do
    @info "Reloading!"

    try
      Genie.WebChannels.message(WEBCHANNEL_NAME, "autoreload:full")
      WebChannels.unsubscribe_disconnected_clients(WEBCHANNEL_NAME)
    catch ex
      @warn ex
    end
  end
end

function assets_js() :: String
  """
  function autoreload_subscribe() {
    Genie.WebChannels.sendMessageTo("autoreload", "subscribe");
    console.log("Autoreloading ready");
  }

  setTimeout(autoreload_subscribe, 2000);

  Genie.WebChannels.messageHandlers.push(function(event) {
    if ( event.data == "autoreload:full" ) {
      location.reload(true);
    }
  });
  """
end

function assets_script() :: String
  """
  <script>
  $(assets_js())
  </script>
  """
end

function assets(; devonly = true) :: String
  if (devonly && Genie.Configuration.isdev()) || !devonly
    """<script src="$SCRIPT_URI"></script>"""
  else
    ""
  end
end

function autoreload(; devonly = true)
  if devonly && !Genie.Configuration.isdev()
    @warn "AutoReload configured for dev environment only. Skipping."
    return nothing
  end

  route(SCRIPT_URI) do
    assets_js() |> Genie.Renderer.Js.js
  end

  channel("/$WEBCHANNEL_NAME/subscribe") do
    WebChannels.subscribe(@params(:WS_CLIENT), WEBCHANNEL_NAME)
  end

  @async GenieAutoReload.watch()
end

end # module