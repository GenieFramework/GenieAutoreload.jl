module GenieAutoReload

using Revise
__revise_mode__ = :eval

using Genie, Genie.Router, Genie.WebChannels
using Distributed, Logging

export autoreload

Genie.config.websockets_server = true

const WEBCHANNEL_NAME = "autoreload"
const SCRIPT_URI = "$(Genie.Assets.external_assets(Genie.config.base_path) ? "" : "/")js/plugins/autoreload.js"
const WATCH_KEY = "autoreload"

function watch(files::Vector{String}, extensions::Vector{String} = Genie.config.watch_extensions) :: Nothing
  @info "Watching $files"

  Genie.config.watch_handlers[WATCH_KEY] = [
    () -> @info("Autoreloading"),
    () -> Genie.WebChannels.broadcast(WEBCHANNEL_NAME, "autoreload:full")
  ]

  Genie.Watch.watchpath(files)

  nothing
end

function watch(files::String)
  watch(String[files])
end

function assets_js() :: String
  """
  function autoreload_subscribe() {
    Genie.WebChannels.sendMessageTo('autoreload', 'subscribe');
    console.info('Autoreloading ready');
  }

  setTimeout(autoreload_subscribe, 2000);

  Genie.WebChannels.messageHandlers.push(function(event) {
    if ( event.data == 'autoreload:full' ) {
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

function routing() :: Nothing
  route(SCRIPT_URI) do
    assets_js() |> Genie.Renderer.Js.js
  end

  channel("/$(WEBCHANNEL_NAME)/subscribe") do
    WebChannels.subscribe(params(:WS_CLIENT), WEBCHANNEL_NAME)
  end

  nothing
end

function deps() :: Vector{String}
  routing()
  [assets()]
end

function autoreload(files::Vector{String}, extensions::Vector{String} = Genie.confg.watch_extensions;
                    devonly::Bool = true)
  if devonly && !Genie.Configuration.isdev()
    @warn "AutoReload configured for dev environment only. Skipping."
    return nothing
  end

  routing()

  GenieAutoReload.watch(files, extensions)
end

function autoreload(files...; extensions::Vector{String} = Genie.config.watch_extensions, devonly = true)
  autoreload([files...], [extensions...]; devonly = devonly)
end

end # module