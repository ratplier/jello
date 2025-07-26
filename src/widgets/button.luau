--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")

local colors = config.colors

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	clicked: source<boolean>,
	right_clicked: source<boolean>,
	middle_clicked: source<boolean>,
	
	hovered: source<boolean>,
}
export type arguments = {
	text: string?,
	padding: number?,
}

return ui.widget("button", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local last_clicked = root.source(-1)
	local last_right_clicked = root.source(-1)
	local last_middle_clicked = root.source(-1)
	
	local state: state = {
		hovered = root.source(false),
		clicked = root.derive(function() return last_clicked() >= root.get_tick() end),
		right_clicked = root.derive(function() return last_right_clicked() >= root.get_tick() end),
		middle_clicked = root.derive(function() return last_middle_clicked() >= root.get_tick() end),
	}
	
	local clicked = root.derive(function()
		return state.clicked() or state.right_clicked() or state.middle_clicked()
	end)
	
	root.mount(function()
		return root.create("TextLabel") {
			Active = true,
			AutomaticSize = Enum.AutomaticSize.XY,
			
			Text = args.text or "Button",
			TextSize = config.textSize,
			Font = config.font,

			ui.padding(args.padding or 3),
			ui.apply_color("Text", colors.Text),
			ui.apply_color("Background", function()
				return
					if clicked() then colors.ButtonActive
					elseif state.hovered() then colors.ButtonHovered
					else colors.Button
			end),
			
			ui.entered(function() state.hovered(true) end),
			ui.exited(function() state.hovered(false) end),
			
			ui.clicked("Button1", function()
				last_clicked( root.get_tick() )
			end),
			ui.clicked("Button2", function()
				last_right_clicked( root.get_tick() )
			end),
			ui.clicked("Button3", function()
				last_middle_clicked( root.get_tick() )
			end)
		}
	end)
	
	return state
end)
