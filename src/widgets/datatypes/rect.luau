--!strict
local config = require("../../config")
local input = require("../../utils/input")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

local row = require("../format/row")
local text = require("../text")

type source<T> = root.source<T>
type value<T> = root.value<T>
type partial<T> = root.partial<T>

export type state = {
    value: source<Rect>,
    hovered: source<boolean>,
    changed: source<boolean>,
}
export type arguments = {
    value: value<Rect>,

    text: string,
    min: number,
    max: number,
}

local DEFAULT_MIN = -1e6
local DEFAULT_MAX = 1e6
local DEFAULT_VALUE = Rect.new(0, 0, 0, 0)

local function decimal_len(n)
	local s = tostring(n)
    local l = s:len()
	local i = s:find("%.") or l
	return l - i
end

return {
    base = ui.widget("rect-input", function(arguments: partial<arguments>)
        local changed = root.event()
        local args = root.default(arguments, {
            text = "input rect", min = DEFAULT_MIN, max = DEFAULT_MAX,
            value = DEFAULT_VALUE
        }) :: arguments

        local state: state = {
            hovered = root.source(false),
            changed = root.source(false),
            value = root.from(args.value) :: source<Rect>,
        }

        row({ fixed_size = true }).with(function()
            local increment = config.default_value_increment
            local inputs = input.create_data_type_inputs(state.value, {
                min = args.min,
                max = args.max,
                increment = increment,
                decimal_places = decimal_len(increment),
            })

            if inputs.changed() then
                state.value( inputs.value() )
                changed.fire()
            end

            text { text = args.text }
        end)

        state.changed(changed.fired())
        return state
    end)
}