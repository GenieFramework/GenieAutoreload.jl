# GenieAutoReload plugin
## Auto reload functionality for Genie plugins.

GenieAutoReload monitors the indicated files and folders (recursively) and automatically recompiles the Julia code and reloads the corresponding browser window. 

To use in the app, add the following lines of code: 

```julia
using Genie, Genie.Renderer.Html # some app deps
using GenieAutoReload

# UI rendering code
# As part of the HTML UI code we need to load the autoreload.js file
# so this needs to be added in order to output the corresponding 
# <script> tag.
view = [
  p("Hello world")
  GenieAutoReload.assets()
]
html(view)

# Add files and folders to be watched for changes
# Folders will be added recursively
push!(GenieAutoReload.WATCHED_FOLDERS, pwd())

# Enable autoreload
GenieAutoReload.autoreload()
```

By default autoreloading is activated only when the Genie app runs in development. To force it to run 
in other environments, use `GenieAutoReload.autoreload(devonly = false)`. 

Similarely, the assets are included only when the Genie app runs in development (otherise `assets()` won't return anything 
and won't inject the `<script>` tag). To enable the assets in other environments, use ` and `GenieAutoReload.assets(devonly = false)`.
