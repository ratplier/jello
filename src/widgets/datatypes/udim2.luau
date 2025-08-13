--!strict
local config = require("../../config")
local input = require("../../utils/input")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type value<T> = root.value<T>
type partial<T> = root.partial<T>

export type state = {
    value: source<UDim2>,
    hovered: source<boolean>,
    changed: source<boolean>,
}
export type arguments = {
    value: value<UDim2>,

    text: string,
    min: number,
    max: number,
}

local DEFAULT_MIN = -1e6
local DEFAULT_MAX = 1e6
local DEFAULT_VALUE = UDim2.new(0, 0, 0, 0)

return {
    base = ui.widget("udim2_input", function(arguments: partial<arguments>?)
        local args = root.default(arguments, {
            text = "udim2 input", min = DEFAULT_MIN, max = DEFAULT_MAX,
            value = DEFAULT_VALUE
        }) :: arguments

        local state: state = {
            hovered = root.source(false),
            changed = root.source(false),
            value = root.from(args.value) :: source<UDim2>,
        }

        input.row({ fixed_size = true }).with(function()
            local increment = config.default_value_increment
            local inputs = input.create_data_type_inputs(state.value, {
                min = args.min,
                max = args.max,
                increment = increment,
            })

            state.changed(inputs.changed())
            input.create_input_label(args.text)
        end)

        return state
    end)
}