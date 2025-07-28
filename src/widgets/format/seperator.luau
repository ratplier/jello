--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

local colors = config.colors

type partial<T> = root.partial<T>
type source<T> = root.source<T>

export type arguments = { text: string? }

return ui.widget("seperator", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local has_text = args.text ~= nil
	local thickness = 1
	
	root.mount(function()
		return root.create("Frame") {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			
			ui.padding(5, 0),
			ui.list_layout("Horizontal", 0),
			
			-- left
			root.create("Frame") {
				Size = UDim2.new(0, 10, 0, thickness),
				LayoutOrder = 1,
				
				ui.apply_color("Background", colors.Seperator),
			},
			
			-- text
			root.create("TextLabel") {
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 2,
				
				Text = root.default(args.text, ""),
				TextSize = config.textSize,
				Font = config.font,

				ui.apply_color("Text", colors.Text),
				root.conditional(has_text, function()
					return ui.padding(0, 3, 5, 5)
				end),
			},
			
			-- right
			root.create("Frame") {
				LayoutOrder = 3,
				Size = UDim2.new(0, 0, 0, thickness),
				
				ui.flexitem("Grow"),
				ui.apply_color("Background", colors.Seperator),
			}
		}
	end)
	
	return {}
end)
