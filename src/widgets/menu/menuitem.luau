local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
    clicked: source<boolean>,
    hovered: source<boolean>,
}

return ui.widget("menuitem", function(text: string)
    local clicked = root.event()
    local state: state = {
        clicked = root.source(false),
        hovered = root.source(false),
    }

    local button = root.create("TextButton") {
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, config.menu_item_width, 0, 0),

        Text = text,
        RichText = true,

        paint.text(),
        paint.menuitem(state.clicked, state.hovered),

        ui.padding(config.padding/2, config.padding),
        ui.hovered(state.hovered),
        ui.clicked("Button1", function()
            clicked.fire()
        end),
    } :: TextButton

    root.mount(button)

    state.clicked(clicked.fired())
    return state
end)

