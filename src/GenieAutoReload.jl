module GenieAutoReload

using Genie, Genie.Plugins

function install(dest::String; force = false) :: Nothing
  src = abspath(normpath(joinpath(@__DIR__, "..", Genie.Plugins.FILES_FOLDER)))

  for f in readdir(src)
    isfile(f) && continue
    isdir(f) || startswith(f, ".") || mkpath(joinpath(src, f))

    Genie.Plugins.install(joinpath(src, f), dest, force = force)
  end

  nothing
end

end # module