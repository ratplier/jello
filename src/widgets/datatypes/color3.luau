--!strict
local config = require("../../config")
local input = require("../../utils/input")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type value<T> = root.value<T>
type partial<T> = root.partial<T>

export type state = {
    value: source<Color3>,
    hovered: source<boolean>,
    changed: source<boolean>,
}
export type arguments = {
    value: value<Color3>,
    text: string,
    increment: number,

    noPreview: boolean?,
    hsv: boolean?,
}

local DEFAULT_MIN = 0
local DEFAULT_MAX = 255
local DEFAULT_VALUE = Color3.new(1, 1, 1)

return {
    base = ui.widget("color3_input", function(arguments: partial<arguments>?)
        local args = root.default(arguments, {
            text = "color3 input", value = DEFAULT_VALUE,
            increment = config.default_value_increment
        }) :: arguments

        local state: state = {
            hovered = root.source(false),
            changed = root.source(false),
            value = root.from(args.value) :: source<Color3>,
        }

        input.row({ fixed_size = true }).with(function()
            local ctrl_pressed = root.keys_pressed("LeftControl", "RightControl")
            local increment = args.increment
            if ctrl_pressed then increment *= 100 end

            local inputs = input.create_data_type_inputs(state.value, {
                min = DEFAULT_MIN,
                max = DEFAULT_MAX,
                increment = increment,
                id_suffix = if args.hsv then "_HSV" else "",

                has_color_preview = not args.noPreview,
            })

            state.changed(inputs.changed())
            input.create_input_label(args.text)
        end)

        return state
    end)
}