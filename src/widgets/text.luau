--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")

local colors = config.colors

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {}
export type arguments = {
	text: string?,
	richText: boolean?,
	color: Color3?,
	wrapped: boolean?,
}

return ui.widget("text", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	
	root.mount(function()
		return root.create("TextLabel") {
			AutomaticSize = Enum.AutomaticSize.XY,
			
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			Interactable = false,

			TextSize = config.textSize,
			Font = config.font,
			
			ui.apply_color("Text", colors.Text),
			
			Text = root.default(args.text, "text"),
			TextWrapped = root.default(args.wrapped, false),
			RichText = root.default(args.richText, false),
			
			root.conditional(args.color ~= nil, function()
				return { TextColor3 = args.color }
			end),
		}
	end)
	
	return {} :: state
end)
