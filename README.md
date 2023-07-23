# GenieAutoReload plugin

## Auto reload functionality for Genie plugins.

GenieAutoReload monitors the indicated files and folders (recursively) and automatically recompiles the Julia code and reloads the corresponding browser window.

To use in the app, add the following lines of code:

```julia
using Genie, Genie.Renderer.Html # some app deps

# load GenieAutoReload
using GenieAutoReload

# UI rendering code
# As part of the HTML UI code we need to load the autoreload.js file
# so this needs to be added in order to output the corresponding
# <script> tag.
view = [
  p("Hello world")
  Genie.Assets.channels_support() # auto-reload functionality relies on channels
  GenieAutoReload.assets()
]
html(view)

# Enable autoreload
Genie.config.websockets_server = true
GenieAutoReload.autoreload(pwd())
```

By default autoreloading is activated only when the Genie app runs in development. To force it to run in other environments, use `GenieAutoReload.autoreload(devonly = false)`.

Similarely, the assets are included only when the Genie app runs in development (otherwise `assets()` won't return anything and won't inject the `<script>` tag). To enable the assets in other environments, use `GenieAutoReload.assets(devonly = false)`.
