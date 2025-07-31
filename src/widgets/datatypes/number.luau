--!strict
local input = require("../../utils/input")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

local row = require("../format/row")
local text = require("../text")

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

local function decimal_len(n)
	local s = tostring(n)
    local l = s:len()
	local i = s:find("%.") or l
	return l - i
end

return {
    base = ui.widget("number-input", function(arguments: partial<arguments>)
        local changed = root.event()
        local args = root.default(arguments, {
            text = "input number", min = DEFAULT_MIN, max = DEFAULT_MAX,
            value = DEFAULT_VALUE
        }) :: arguments

        local state: state = {
            hovered = root.source(false),
            changed = root.source(false),
            value = root.from(args.value) :: source<number>,
        }

        row().with(function()
            local ctrl_pressed = root.keys_pressed("LeftControl", "RightControl")
            local increment = if ctrl_pressed then args.increment * 100 else args.increment
            
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

            root.conditional(args.noButtons ~= true, function()
                return input.create_increment(
                    state.value,
                    increment,
                    function() changed.fire() end
                )
            end)

            text { text = args.text }
        end)

        state.changed(changed.fired())
        return state
    end)
}