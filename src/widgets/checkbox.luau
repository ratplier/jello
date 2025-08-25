--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local row = require("./format/row")
local text = require("./text")

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
	checked: source<boolean>,
	clicked: source<boolean>,
}
export type arguments = {
	text: string?
}

return ui.widget("checkbox", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
	local last_click = root.source( root.get_tick() )
	
	local state: state = {
		hovered = root.source(false),
		checked = root.source(false),
		clicked = root.derive(function()
			return last_click() >= root.get_tick()
		end),
	}
	
	row().with(function()
		local checkbox = root.create("Frame") {
			Active = true,
			Size = UDim2.fromOffset(18, 18),
			
			root.create("ImageLabel") {
				BackgroundTransparency = 1,
				Image = assets.checkMark,
				Size = UDim2.fromScale(1, 1),
				
				ImageTransparency = function()
					return if state.checked() then 0 else 1
				end,

				paint.image(),
			},

			paint.button(state.clicked, state.hovered),

			ui.padding(config.padding / 2),
			ui.hovered(state.hovered),
			ui.clicked("Button1", function()
				state.checked( not state.checked() )
				last_click( root.get_tick() )
			end),
		}
		
		if args.text then
			text { text = args.text }
		end

		ui.mount(checkbox)
	end)
	return state
end)
