--!strict
local input = require("../../utils/input")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type value<T> = root.value<T>
type partial<T> = root.partial<T>

export type state = {
    value: source<number>,
    hovered: source<boolean>,
    changed: source<boolean>,
}
export type arguments = {
    value: value<number>,

    text: string,
    min: number,
    max: number,
    increment: number,

    noButtons: boolean?,
}

local DEFAULT_MIN = -1e6
local DEFAULT_MAX = 1e6
local DEFAULT_VALUE = 0

return {
    base = ui.widget("number_input", function(arguments: partial<arguments>)
        local args = root.default(arguments, {
            text = "number input", min = DEFAULT_MIN, max = DEFAULT_MAX,
            value = DEFAULT_VALUE, increment = 1
        }) :: arguments

        local state: state = {
            hovered = root.source(false),
            changed = root.source(false),
            value = root.from(args.value) :: source<number>,
        }

        input.row({ fixed_size = true }).with(function()
            local ctrl_pressed = root.keys_pressed("LeftControl", "RightControl")
            local increment = args.increment
            if ctrl_pressed then increment *= 100 end
            
            local inputs = input.create_data_type_inputs(state.value, {
                min = args.min,
                max = args.max,
                increment = increment,
                decimal_places = input.get_decimal_places(increment),

                has_buttons = not args.noButtons,
            })

            state.changed(inputs.changed())
            input.create_input_label(args.text)
        end)

        return state
    end)
}