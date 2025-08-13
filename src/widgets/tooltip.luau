--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local TOOLTIP_OFFSET = vector.create(10, 15)

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
    active: source<boolean>,
	hovered: source<boolean>,
}
export type arguments = {
	text: string?,
    richText: boolean?,
    color: Color3?,
}

return ui.widget("tooltip", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local state: state = {
		active = root.source(false),
        hovered = root.source(false),
	}
	
	local main = root.create("TextLabel") {
        AutomaticSize = Enum.AutomaticSize.XY,
        
        Position = function()
            local mouse_pos = ui.mouse_position() - ui.inset()
            mouse_pos += TOOLTIP_OFFSET
            return UDim2.fromOffset(mouse_pos.x, mouse_pos.y)
        end,

        paint.text(),
        paint.tooltip(),

        ui.padding(config.spacing),
        ui.hovered(state.hovered),
        ui.constrain(nil, nil, 250, nil),
        
        TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
        Text = root.default(args.text, "text"),
        RichText = root.default(args.richText, false),
        
        root.conditional(args.color ~= nil, function()
            return { TextColor3 = args.color }
        end),
    }
	
    root.mount(main, "root")
	return state
end)
