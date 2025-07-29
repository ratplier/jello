--!strict
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
}
export type arguments = {
	text: string?,
	richText: boolean?,
	color: Color3?,
	wrapped: boolean?,
}

return ui.widget("text", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local state: state = {
		hovered = root.source(false),
	}
	
	root.mount(function()
		return root.create("TextLabel") {
			AutomaticSize = Enum.AutomaticSize.XY,
			
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, 16),

			paint.text(),
			ui.hovered(state.hovered),
			
			Text = root.default(args.text, "text"),
			TextWrapped = root.default(args.wrapped, false),
			RichText = root.default(args.richText, false),
			
			root.conditional(args.color ~= nil, function()
				return { TextColor3 = args.color }
			end),
		}
	end)
	
	return state
end)
