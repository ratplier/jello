--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")

local row = require("./format/row")
local text = require("./text")

local assets = config.assets
local colors = config.colors

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
	checked: source<boolean>,
}
export type arguments = {
	label: string?
}

return ui.widget("checkbox", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local last_click = root.source( root.get_tick() )
	
	local state = {
		hovered = root.source(false),
		checked = root.source(false),
		clicked = root.derive(function()
			return last_click() >= root.get_tick()
		end),
	}
	
	if args.label then
		row()
	end
	
	root.mount(function()
		return root.create("Frame") {
			Active = true,
			Size = UDim2.fromOffset(18, 18),
			
			root.create("ImageLabel") {
				BackgroundTransparency = 1,
				Image = assets.checkMark,
				Size = UDim2.fromScale(1, 1),
				
				ImageTransparency = function()
					return if state.checked() then 0 else 1
				end,
			},

			ui.padding(2),
			ui.apply_color("Background", function()
				return
					if state.clicked() then colors.ButtonActive
					elseif state.hovered() then colors.ButtonHovered
					else colors.Button
			end),
			
			ui.entered(function() state.hovered(true) end),
			ui.exited(function() state.hovered(false) end),
			
			ui.clicked("Button1", function()
				state.checked( not state.checked() )
				last_click( root.get_tick() )
			end),
		}
	end)
	
	if args.label then
		text({ text = args.label })
		root.close_scope()
	end

	return state
end)
