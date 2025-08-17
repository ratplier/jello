--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

return ui.widget("menubar", function()
    local menubar = root.create("Frame") {
        Size = UDim2.new(1, 0, 0, 22),

        LayoutOrder = 1,
        paint.menubar(),
        
        ui.padding(0, config.spacing),
        ui.list_layout("Horizontal", 0),
    }

    ui.mount(menubar)
    return ui.start_scope(menubar)
end)
