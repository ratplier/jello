--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")

local colors = config.colors

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	text_changed: source<boolean>,
	focused: source<boolean>,
	hovered: source<boolean>,
	text: source<string>,
}
export type arguments = {
	text: string,
	placeholder: string,
	multiLine: boolean?,
    wrapped: boolean?,
    readOnly: boolean?,
}

return ui.widget("textinput", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {
        multiLine = false,
        readOnly = false,
        placeholder = "",
        text = "",
        wrapped = false,
    }) :: arguments

    local last_text_change = root.source(-1)
	local state: state = {
		focused = root.source(false),
        hovered = root.source(false),
		text = root.source(args.text),
		text_changed = root.derive(function()
            return last_text_change() >= root.get_tick()
		end),
	}
	
	root.mount(function()
		return root.create("TextBox") {
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.new(1, 0, 0, 16),

			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,

			Font = config.font,
            Text = args.text,
            TextSize = config.textSize,

			PlaceholderText = args.placeholder,
            TextEditable = not args.readOnly,
            MultiLine = args.multiLine,
            TextWrapped = args.multiLine or args.wrapped,

            Focused = function(self: TextBox)
                state.focused( true )
            end,
            FocusLost = function(self: TextBox)
                state.text( self.Text )
                state.focused( false )
                last_text_change( root.get_tick() )
            end,

            ui.padding(5),
            ui.hovered(state.hovered),
			ui.apply_color("Text", colors.Text),
            ui.apply_color("Background", colors.FrameBg),
		}
	end)

	return state
end)
