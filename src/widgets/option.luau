--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
	selected: source<boolean>,
	clicked: source<boolean>,
}
export type arguments = {
	text: string,
	value: any,
	state: source<any>,
}

return ui.widget("option", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments
    local clicked = root.event()

	local state: state = {
		hovered = root.source(false),
		clicked = root.derive(clicked.fired),
		selected = root.derive(function()
            return args.state() == args.value
        end),
	}

	local main = root.create("TextButton") {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),

		Text = args.text,

        paint.text(),
        paint.option(state.selected, state.clicked, state.hovered),

        ui.padding(config.padding),
		ui.hovered(state.hovered),
		ui.clicked("Button1", function()
			args.state(args.value)
			clicked.fire()
		end),
	}

	root.mount(main)
	return state
end)
