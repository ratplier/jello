## Proposed Syntax

### Window API

- ✅ Window
- ✅ Tooltip

```luau
jello.window { title = "a jello window" } .with(function(window)
    if window.active() then
        jello.tooltip { text = "this is a tool tip" }
    end
end)
```

### Menu Widget API

- ✅ MenuBar
- ✅ Menu
- ✅ MenuItem
- ❌ MenuToggle

```luau
window.menubar()
    jello.menu("info").with(function()
        local lazy_load = jello.menutoggle("lazy load")
        local about = jello.menuitem("about")

        if lazy_load.checked() then set_load_mode("lazy") end

        jello.seperator()

        jello.text { text = "jello is cool." }
    end)
jello.close()
```

Format Widget API

- ✅ Separator
- ✅ Indent
- ✅ SameLine (row)
- ✅ Group (column)

```luau
jello.indent()

jello.group().with(function()
    jello.row().with(function()
        jello.text { text = "header" }
        jello.checkbox { text = "hi" }
    end)

    jello.seperator()

    jello.text { text = "another label" }
end)

jello.close()
```

Text Widget API

- ✅ Text
- ✅ SeparatorText
- ✅ InputText

```luau
jello.seperator { text = "enter your name:" }

local input = jello.textinput { placeholder = "name" }
jello.text { text = `hello, {input.text()}` }
```

Basic Widget API

- ✅ Button
- ✅ SmallButton (Button + padding)
- ✅ Checkbox
- ✅ RadioButton

```luau
jello.button { text = "click me", padding = -2 }
jello.checkbox { text = "hi" }

local selected = jello.source("1")
local data = { "1", "2", "3" }

jello.row().with(function()
    for i = 1, 3 do
        jello.radiobutton { state = `{i}`, index = selected }
    end
end)
```

Image Widget API

- ✅ Image
- ✅ ImageButton

```luau
jello.image { image = "asset://jello.png" }
jello.imagebutton { image = "asset://jello.png" }
```

Tree Widget API

- ✅ Tree (Section)
- ✅ CollapsingHeader (Header)

```luau
jello.header { text = "hello" } .with(function()
    jello.text { text = "hi" }

    jello.section { text = "subsection" }
end)
```

Tab Widget API

- ❌ TabBar
- ❌ Tab

```luau
jello.tabs { text = "tab group" } .with(function()
    jello.tab { text = "tab 1" } .with(function()
        jello.text { text = "hello from tab 1" }
    end)

    jello.tab { text = "tab 2" } .with(function()
        jello.text { text = "hello from tab 2" }
    end)
end)
```

Input/Drag Widget API

- ✅ Number
- ✅ Vector2
- ✅ Vector3
- ✅ UDim
- ✅ UDim2
  
- ✅ Rect
- ✅ Color3
- ✅ Color4
- ❌ Enum (not yet)

```luau
local number = jello.number()
local number_source = number.value
number_source(400)

jello.vector2()
jello.vector3()
jello.udim()
jello.udim2()
jello.rect()
```

Slider Widget API

- ❌ Number
- ❌ Vector2
- ❌ Vector3
- ❌ UDim
- ❌ UDim2
- ❌ Rect

```luau
jello.number_slider()
jello.vector2_slider()
jello.vector3_slider()
jello.udim_slider()
jello.udim2_slider()
jello.rect_slider()
```

Combo Widget API

- ❌ Selectable (option)
- ❌ Combo
- ❌ ComboArray (dropdown)
- ❌ ComboEnum (dropdown)

```luau
local enum = {
    -- key = displayed value
    no_name = "nameless",
    single_name = "named",
    name = "family named",
}
local selection = jello.source("name")

jello.combo { states = enum, value = selection }
jello.dropdown().with(function()
    for key, text_value in enum do
        jello.option { choice = selection, option = key, text = text_value }
    end
end)
```

Plot Widget API

- ❌ ProgressBar
- ❌ PlotLines
- ❌ PlotHistogram

```luau
jello.gauge { range_min = 0, range_max = 100 } -- percentage
```

Table Widget API

- ❌ Table

```luau
jello.table {
    data = {
        {"", "column 2"},
        {"row 1", "data"},
        {"row 2", "data"},
    },
}
```
