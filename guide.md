## Proposed Syntax

### Window API

- [ ] Window

```luau
type window_state = {
    active: read source<boolean>,

    minimized: source<boolean>,
    resizable: source<boolean>,
    draggable: source<boolean>,

    position: source<vector>,
    size: source<vector>,
    zindex: read source<number>,

    menubar: () -> scope,
}

type window_arguments = {
    title: string,
}

function jello.window(window_argument): window_state
```

- [ ] Tooltip

```luau
type tooltip_state = {
    hovered: read source<boolean>,
}

type tooltip_arguments = {
    text: string,
    richtext: boolean?,
}

function jello.tooltip(tooltip_argument): tooltip_state
```

Example

```luau
jello.window { title = "a jello window" } .with(function(window)
    local text = jello.text { text = "hover over me!" }
    if button.hovered() then
        jello.tooltip { text = "hello!" }
    end
end)
```

### Menu Widget API

- [x] MenuBar

No specific info, not very useful

```luau
function jello.menubar()
```

- [ ] Menu

```luau
type menu_state = {
    open: read source<boolean>,
    clicked: read event,
    hovered: read source<boolean>,
}

function jello.menu(name: string?): menu_state
```

- [ ] MenuItem

```luau
type menu_item_state = {
    clicked: read event,
    hovered: read source<boolean>,
}

function jello.menu_item(text: string): menu_item_state
```

- [ ] MenuToggle

```luau
type menu_toggle_state = {
    clicked: read event,
    checked: read source<boolean>,
    hovered: read source<boolean>,
}

function jello.menu_toggle(text: string): menu_toggle_state
```

Example

```luau
window.menubar()
    jello.menu("info").with(function()
        local lazy_load = jello.menu_toggle("lazy load")
        local about = jello.menu_item("about")

        if lazy_load.clicked() then
            set_lazy_load(lazy_load.checked())
        end

        jello.seperator()

        jello.text { text = "jello is cool." }
    end)
jello.close()
```

Format Widget API

- [x] Separator

```luau
type seperator_arguments = {
    text: string
}

function jello.seperator(seperator_arguments)
```

- [x] Indent
- [x] SameLine (row)
- [x] Group (column)

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

- [x] Text
- [x] SeparatorText
- [x] InputText

```luau
jello.seperator { text = "enter your name:" }

local input = jello.textinput { placeholder = "name" }
jello.text { text = `hello, {input.text()}` }
```

Basic Widget API

- [ ] Button
- [ ] SmallButton (Button + padding)

```luau
type button_arguments = {
    text: string,
    padding: number?,
}
type button_state = {
    clicked: read source<boolean>,
    hovered: read source<boolean>,
}

function jello.button(button_arguments): button_state
```

- [x] Checkbox

```luau
type checkbox_arguments = {
    text: string,
    checked: source<boolean>?,
}
type checkbox_state = {
    checked: read source<boolean>,
}

function jello.checkbox(checkbox_arguments): checkbox_state
```

- [ ] RadioButton

```luau
type radiobutton_arguments = {
    text: string,
    index: source<any>,
    state: any,
}

function jello.radiobutton(radiobutton_arguments): scope
```

Example

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

- [x] Image
- [x] ImageButton

```luau
jello.image { image = "asset://jellofish.png" }
jello.imagebutton { image = "asset://jellofish.png" }
```

Tree Widget API

- [x] Tree (Section)
- [x] CollapsingHeader (Header)

```luau
jello.header { text = "hello" } .with(function()
    jello.text { text = "hi" }

    jello.section { text = "section" }
end)
```

Tab Widget API

- [ ] TabBar
- [ ] Tab

```luau
jello.tab_group { text = "tab group" } .with(function()
    jello.tab { text = "tab 1" } .with(function()
        jello.text { text = "hello from tab 1" }
    end)

    jello.tab { text = "tab 2" } .with(function()
        jello.text { text = "hello from tab 2" }
    end)
end)
```

Input/Drag Widget API

- [x] Number
- [x] Vector2
- [x] Vector3
- [x] UDim
- [x] UDim2
  
- [x] Rect
- [x] Color3
- [x] Color4
- [ ] Enum (not yet)

```luau
local number = jello.number()
number.value(400)

jello.vector2()
jello.vector3()
jello.udim()
jello.udim2()
jello.rect()
```

Slider Widget API

- [ ] Number
- [ ] Vector2
- [ ] Vector3
- [ ] UDim
- [ ] UDim2
- [ ] Rect

```luau
jello.number_slider()
jello.vector2_slider()
jello.vector3_slider()
jello.udim_slider()
jello.udim2_slider()
jello.rect_slider()
```

Combo Widget API

- [ ] Selectable (option)
- [ ] Combo
- [ ] ComboArray (dropdown)
- [ ] ComboEnum (dropdown)

```luau
local enum = {
    -- index = option
    no_name = "nameless",
    single_name = "named",
    name = "family named",
}
jello.combo { states = enum }

-- is equivalent to

jello.dropdown().with(function()
    local choice = jello.source("no_name") -- keyof<enum>

    for option, text in enum do
        jello.option { choice = choice, option = option, text = text }
    end
end)
```

Plot Widget API (not soon, will be like <https://github.com/epezent/implot>)

- [ ] ProgressBar
- [ ] PlotLines
- [ ] PlotHistogram

```luau
type plot_arguments = {
    label: string,
    x_axis_label: string?,
    y_axis_label: string?,
}

type plot_lines_arguments = {
    data: array<vector>,
}

type plot_histogram_arguments = {
    bins: number?,
    data: array<number>,
}

type plot_bar_arguments = {
    data: array<vector>, -- {x = category, y = value}
}
```

```luau
jello.gauge { range_min = 0, range_max = 100 } -- percentage

jello.plot {
    label = "performance",
    x_axis_label = "frames",
    y_axis_label = "time (ms)",
} .with(function()
    local my_data = jello.source {
        vector.create(1, 2),
        vector.create(2, 3),
        vector.create(5, 6),
    }

    jello.plot_lines { data = my_data }
end)

jello.plot {
    label = "distribution",
    x_axis_label = "value",
    y_axis_label = "frequency",
} .with(function()
    local histogram_data = jello.source { 1, 2, 2, 3, 3, 3, 4, 4, 5 }

    jello.plot_histogram {
        data = histogram_data,
        bins = 5,
    }
end)
```

Source API (incomplete)

```luau
local source = jello.state(0)
source(10)
print(source()) -- 10

source.write(20)
print(source.read()) -- 20
```

Binding API (incomplete)

```luau
local comment_text = jello.source("this is a comment")
jello.textinput().bind(comment_text) -- choose specified default index

local window_position = jello.source(vector.create(50, 50))
local window_size = jello.source(vector.create(800, 600))

jello.window { title = "window" } .bind {
    position = window_position,
    size = window_size
}

window_size(vector.create(200, 200))
comment_text("this is super cool!")
```

With API (complete)

```luau
jello.row()
    jello.text { text = "hi" }
jello.close()

-- now you can

jello.row().with(function()
    jello.text { text = "hi" }
end)
```

I will still be adding other stuff into here on request soon. Every non widget component should be self explainatory from looking through the source code and types from the interface. To be honest ive been slacking on this project quite alot.
