module GenieAutoReload

using Genie, Genie.Plugins

function install(dest::String; force = false)
  src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isdir(f) || continue
    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end
end

end # module