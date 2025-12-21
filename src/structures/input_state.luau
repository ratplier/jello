type vector2 = vector

export type input_state_updater = (self: input_state, set_state: (input, boolean) -> ()) -> ()
export type input =
    | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
    | "zero" | "one" | "two" | "three" | "four" | "five" | "six" | "seven" | "eight" | "nine"

    | "space" | "apostrophe" | "comma" | "minus" | "period" | "slash"
    | "semicolon" | "equal" | "left_bracket" | "backslash" | "right_bracket" | "grave_accent"
    | "enter" | "left_shift" | "right_shift" | "left_control" | "right_control" | "left_alt" | "right_alt" | "tab" | "backspace" | "escape" | "tilde"

    | "mouse1" | "mouse2" | "mouse3"

export type input_state = {
    inputs: { [input]: true },

    mouse_position: vector2,
    mouse_delta: vector2,
    scroll_delta: number,

    input_pressed: (self: input_state, input: input) -> boolean,
    input_released: (self: input_state, input: input) -> boolean,
}

local input_state = {}

function input_state.new(updater: input_state_updater): input_state
    local self = {
        inputs = {},
        mouse_position = vector.zero,
        mouse_delta = vector.zero,
        scroll_delta = 0,
    }

    self.input_pressed = input_state.input_pressed
    self.input_released = input_state.input_released

    updater(self, function(index, state: boolean)
        self.inputs[index] = if state then true else nil
    end)
    return self
end

function input_state.input_pressed(self: input_state, input: input): boolean
    print(self.inputs[input])
    return self.inputs[input]
end

function input_state.input_released(self: input_state, input: input): boolean
    return not self.inputs[input]
end

return input_state