using Genie, Genie.Router, Genie.WebChannels, Genie.Util, Genie.Loggers
using Revise
using Distributed

Genie.config.websocket_server = true

const WEBCHANNEL_NAME = "autoreload"
const GENIE_AUTORELOAD = true
const WATCHED_FOLDERS = ["app", "config", "lib", "plugins", "public"]

channel("/$WEBCHANNEL_NAME/subscribe") do
  WebChannels.subscribe(@params(:WS_CLIENT), WEBCHANNEL_NAME)
  @show "Subscription OK"
end

function collect_watched_files(folders::Vector{String} = String[])
  result = String[]

  for f in folders
    push!(result, Genie.Util.walk_dir(f, only_extensions = ["jl", "html", "md", "js", "css"])...)
  end

  result
end

function watch()
  log("Watching $WATCHED_FOLDERS")
  entr(collect_watched_files(WATCHED_FOLDERS)) do
    log("Reloading!")
    Genie.WebChannels.message("autoreload", "autoreload:full")
  end
end

@async watch()
@async WebChannels.unsubscribe_disconnected_clients(WEBCHANNEL_NAME)