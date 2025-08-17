--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type arguments = {
    indent: number,
    padding: number,
}

return ui.widget("indent", function(arguments: root.partial<arguments>?)
    local args = root.default(arguments, { padding = 0, indent = 25 }) :: arguments

    local indent = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),

        ui.padding(0, 0, args.indent, 0),
        ui.list_layout("Vertical", config.spacing),
    }

    ui.mount(indent)
    return ui.start_scope(indent)
end)