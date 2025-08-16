--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	hovered: source<boolean>,
	clicked: source<boolean>,
}
export type arguments = {
	text: string,
}

return ui.widget("menu", function(arguments: partial<arguments>?)
	local args = root.default(arguments, { text = "Menu" }) :: arguments
    local clicked = root.event()
	local state: state = {
		hovered = root.source(false),
		clicked = root.derive(clicked.fired),
	}

	local main = root.create("TextButton") {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),

		Text = args.text,

        paint.text(),
		paint.menubutton(state.clicked, state.hovered),

		ui.hovered(state.hovered),
        ui.padding(0, config.spacing),
		ui.clicked("Button1", function()
			clicked.fire()
		end),
	}

	root.mount(main)
	return state
end)

