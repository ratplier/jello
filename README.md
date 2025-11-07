# jello

immediate mode visualization library
inspired by iris and imgui

guide: [guide.md](guide.md)

## quickstart
```luau
local jello = require("jello").init()
local demo = require("jello/demo")

jello.connect(demo)
```
```luau
local jello = require("jello").init()

jello.connect(function()
    jello.window { title = "hello jello!" } .with(function(window)
        jello.text { text = "welcome" }
    end)
end)
```

## showcase
https://github.com/user-attachments/assets/12bafe0d-70c2-4c17-939c-0aef1076e6df
