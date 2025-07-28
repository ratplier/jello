--!strict
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local row = require("./format/row")
local text = require("./text")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
    selected: source<boolean>,
	clicked: source<boolean>,
}
export type arguments = {
    index: any,
    text: string?,
	state: source<any>,
}

return ui.widget("radiobutton", function(arguments: partial<arguments>?)
	local args = root.default(arguments, { state = root.source(nil) }) :: arguments
	local last_click = root.source( root.get_tick() )
	
	local state: state = {
		hovered = root.source(false),
		selected = root.derive(function()
            return args.state() == args.index
        end),
		clicked = root.derive(function()
			return last_click() >= root.get_tick()
		end),
	}

    row().with(function()
        local button = root.create("Frame") {
            Active = true,
            Size = UDim2.fromOffset(18, 18),

            root.create("Frame") {
                Size = UDim2.fromScale(1, 1),
                Visible = state.selected(),

                ui.circle(),
                paint.radialcenter(),
            },
            
            ui.circle(),
            ui.padding(3),
            paint.background(state.clicked, state.hovered),
            
            ui.entered(function() state.hovered(true) end),
            ui.exited(function() state.hovered(false) end),
            
            ui.clicked("Button1", function()
                last_click( root.get_tick() )
                args.state( args.index )
            end),
        }

        if args.text then
            text { text = args.text }
        end
        
        root.mount(button)
    end)

    return state
end)
