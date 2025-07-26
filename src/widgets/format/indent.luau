--!strict
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

type state = {}
export type arguments = {
    indent: number,
}

return ui.widget("group", function(arguments: root.partial<arguments>?)
    local args = root.default(arguments, { indent = 25 }) :: arguments

    local target = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.fromOffset(args.indent, 0),

        ui.list_layout("Vertical", 8),
    }

    local group = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),

        target,
        ui.list_layout("Vertical", 8),
    }


    root.mount(group)
    return ui.start_scope(target, {})
end)