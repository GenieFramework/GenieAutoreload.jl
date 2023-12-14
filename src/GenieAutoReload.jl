module GenieAutoReload

using Revise
__revise_mode__ = :eval

using Genie, Genie.Router, Genie.WebChannels #, Genie.Context
using Distributed, Logging

export autoreload

Genie.config.websockets_server = true

const WEBCHANNEL_NAME = "autoreload"
const WATCH_KEY = "autoreload"
const JS_FILE_NAME = "autoreload"
const assets_config = Genie.Assets.AssetsConfig(package = "GenieAutoReload.jl")

function watch(files::Vector{String}, extensions::Vector{String} = Genie.config.watch_extensions) :: Nothing
  @info "Watching $files"

  Genie.Watch.handlers!(WATCH_KEY, [
    () -> @info("Autoreloading"),
    () -> Genie.WebChannels.broadcast("$WEBCHANNEL_NAME:full")
  ])

  Genie.Watch.watchpath(files)
  Genie.Watch.watch()

  nothing
end

function watch(files::String)
  watch(String[files])
end

function assets_js() :: String
  """
  function autoreload_subscribe() {
    Genie.WebChannels.sendMessageTo('$WEBCHANNEL_NAME', 'subscribe');
    console.info('Autoreloading ready');
  }

  setTimeout(autoreload_subscribe, 2000);

  Genie.WebChannels.messageHandlers.push(function(event) {
    if ( event.data == '$WEBCHANNEL_NAME:full' ) {
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
    Genie.Renderer.Html.script(src = Genie.Assets.asset_path(GenieAutoReload.assets_config, :js, file=JS_FILE_NAME))
  else
    ""
  end
end

function routing() :: Nothing
  if ! Genie.Assets.external_assets(assets_config)
    route(Genie.Assets.asset_route(GenieAutoReload.assets_config, :js; file=JS_FILE_NAME)) do # params
      assets_js() |> Genie.Renderer.Js.js
    end
  end

  channel("/$(WEBCHANNEL_NAME)/subscribe") do # params
    WebChannels.subscribe(params[:wsclient], WEBCHANNEL_NAME)

    "AutoReload subscribed"
  end

  nothing
end

function deps() :: Vector{String}
  routing()
  [assets()]
end

function autoreload(files::Vector{String}, extensions::Vector{String} = Genie.config.watch_extensions;
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