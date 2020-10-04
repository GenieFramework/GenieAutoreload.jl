module GenieAutoReload

using Revise
using Genie, Genie.Router, Genie.WebChannels
using Distributed, Logging

Genie.config.websockets_server = true

const WEBCHANNEL_NAME = "autoreload"
const GENIE_AUTORELOAD = true
const WATCHED_EXTENSIONS = String["jl", "html", "md", "js", "css"]
const SCRIPT_URI = "/js/plugins/autoreload.js"

function collect_watched_files(files::Vector{String} = String[], extensions::Vector{String} = WATCHED_EXTENSIONS) :: Vector{String}
  result = String[]

  for f in files
    try
      push!(result, Genie.Util.walk_dir(f, only_extensions = extensions)...)
    catch ex
      @error ex
    end
  end

  result
end

function watch(files::Vector{String} = String[], extensions::Vector{String} = WATCHED_EXTENSIONS)
  @info "Watching $files"

  entr(collect_watched_files(files, extensions); all = true, postpone = true) do
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

function autoreload(files::Vector{String} = String[], extensions::Vector{String} = WATCHED_EXTENSIONS; devonly = true)
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

  @async GenieAutoReload.watch(files, extensions)
end

function autoreload(files...; extensions::Vector{String} = WATCHED_EXTENSIONS, devonly = true)
  autoreload([files...], [extensions...]; devonly = devonly)
end

end # module