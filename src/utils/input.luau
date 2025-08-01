--!strict
local UserInputService = game:GetService("UserInputService")

local root = require("./rootkit")
local paint = require("./paint")
local ui = require("./uikit")
local config = require("../config")

type source<T> = root.source<T>

export type DataType = "number" | "Vector2" | "Vector3" | "vector" | "UDim" | "UDim2" | "Color3" | "buffer" | "Rect"
export type InputOptions = {
    align: ("Left" | "Center" | "Right")?,
    decimal_places: number?,
    min: number?,
    max: number?,
}
export type options = {
    suffix: string?,
    align_center: boolean?,

    min: number?,
    max: number?,
    step: number?,
    decimal_places: number?,
}

local DATA_TYPES = {"number", "Vector2", "Vector3", "vector", "UDim", "UDim2", "Color3", "buffer", "Rect"}
local DATA_TYPE_SIZES = { number = 1, Vector2 = 2, Vector3 = 3, vector = 3, UDim = 2, UDim2 = 4, Color3 = 3, buffer = 4, Rect = 4 }
local FLOAT_PRECISION = 12

local read_handlers: {[DataType]: (any, number) -> any} = {
    number = function(value: number, index: number): number
        return value
    end,
    Vector2 = function(vec: Vector2, index: number): number
        if index == 1 then return vec.X end
        if index == 2 then return vec.Y end
        error('Index out of range')
    end,
    Vector3 = function(vec: Vector3, index: number): number
        if index == 1 then return vec.X end
        if index == 2 then return vec.Y end
        if index == 3 then return vec.Z end
        error('Index out of range')
    end,
    vector = function(vec: {x: number, y: number, z: number}, index: number): number
        if index == 1 then return vec.x end
        if index == 2 then return vec.y end
        if index == 3 then return vec.z end
        error('Index out of range')
    end,
    UDim = function(udim: UDim, index: number): number
        if index == 1 then return udim.Scale end
        if index == 2 then return udim.Offset end
        error('Index out of range')
    end,
    UDim2 = function(udim2: UDim2, index: number): number
        if index == 1 then return udim2.X.Scale end
        if index == 2 then return udim2.X.Offset end
        if index == 3 then return udim2.Y.Scale end
        if index == 4 then return udim2.Y.Offset end
        error('Index out of range')
    end,
    Rect = function(rect: Rect, index: number): number
        if index == 1 then return rect.Min.X end
        if index == 2 then return rect.Min.Y end
        if index == 3 then return rect.Max.X end
        if index == 4 then return rect.Max.Y end
        error('Index out of range')
    end,
    Color3 = function(color: Color3, index: number): number
        if index == 1 then return color.R * 255 end
        if index == 2 then return color.G * 255 end
        if index == 3 then return color.B * 255 end
        error('Index out of range')
    end,
    buffer = function(color_buffer: buffer, index: number): number
        return buffer.readu8(color_buffer, index - 1)
    end,
}

local write_handlers: {[DataType]: (any, number, any) -> any} = {
    number = function(target: number, index: number, value: number): number
        return value
    end,
    Vector2 = function(target: Vector2, index: number, value: number): Vector2
        if index == 1 then return Vector2.new(value, target.Y) end
        if index == 2 then return Vector2.new(target.X, value) end
        error('Index out of range')
    end,
    Vector3 = function(target: Vector3, index: number, value: number): Vector3
        if index == 1 then return Vector3.new(value, target.Y, target.Z) end
        if index == 2 then return Vector3.new(target.X, value, target.Z) end
        if index == 3 then return Vector3.new(target.X, target.Y, value) end
        error('Index out of range')
    end,
    vector = function(target: {x: number, y: number, z: number}, index: number, value: number): {x: number, y: number, z: number}
        if index == 1 then return {x = value, y = target.y, z = target.z} end
        if index == 2 then return {x = target.x, y = value, z = target.z} end
        if index == 3 then return {x = target.x, y = target.y, z = value} end
        error('Index out of range')
    end,
    UDim = function(target: UDim, index: number, value: number): UDim
        if index == 1 then return UDim.new(value, target.Offset) end
        if index == 2 then return UDim.new(target.Scale, value) end
        error('Index out of range')
    end,
    UDim2 = function(target: UDim2, index: number, value: number): UDim2
        if index == 1 then return UDim2.new(value, target.X.Offset, target.Y.Scale, target.Y.Offset) end
        if index == 2 then return UDim2.new(target.X.Scale, value, target.Y.Scale, target.Y.Offset) end
        if index == 3 then return UDim2.new(target.X.Scale, target.X.Offset, value, target.Y.Offset) end
        if index == 4 then return UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, value) end
        error('Index out of range')
    end,
    Rect = function(target: Rect, index: number, value: number): Rect
        if index == 1 then return Rect.new(value, target.Min.Y, target.Max.X, target.Max.Y) end
        if index == 2 then return Rect.new(target.Min.X, value, target.Max.X, target.Max.Y) end
        if index == 3 then return Rect.new(target.Min.X, target.Min.Y, value, target.Max.Y) end
        if index == 4 then return Rect.new(target.Min.X, target.Min.Y, target.Max.X, value) end
        error('Index out of range')
    end,
    Color3 = function(target: Color3, index: number, value: number): Color3
        if index == 1 then return Color3.fromRGB(value, target.G * 255, target.B * 255) end
        if index == 2 then return Color3.fromRGB(target.R * 255, value, target.B * 255) end
        if index == 3 then return Color3.fromRGB(target.R * 255, target.G * 255, value) end
        error('Index out of range')
    end,
    buffer = function(target: buffer, index: number, value: number): buffer
        buffer.writeu8(target, index - 1, value)
        return target
    end,
}

local DEFAULTS = {
    prefixes = {
        number = { "" },
        Vector2 = { "x: ", "y: " },
        Vector3 = { "x: ", "y: ", "z: " },
        vector = { "x: ", "y: ", "z: " },
        UDim = { "", "" },
        UDim2 = { "", "", "", "" },
        Color3 = { "r: ", "g: ", "b: " },
        buffer = { "r: ", "g: ", "b: ", "a: " }, -- color4
        Rect = { "minX: ", "minY: ", "maxX: ", "maxY: " },
    },
    decimal_places = {
        number = { nil },
        Vector2 = { nil, nil },
        Vector3 = { nil, nil, nil },
        vector = { nil, nil, nil },
        UDim = { 3, 0 },
        UDim2 = { 3, 0, 3, 0 },
        Color3 = { 0, 0, 0 },
        buffer = { 0, 0, 0, 0 }, -- Color4
        Rect = { nil, nil, nil, nil },
    },
}

local function is_valid_data_type(value: any)
    return table.find(DATA_TYPES, typeof(value)) ~= nil
end

local function read_component_value<T>(target: T, index: number): number?
    root.assert(is_valid_data_type(target), "Invalid data type for reading component value.")

    local data_type = typeof(target) :: DataType
    local handler = read_handlers[data_type]

    if handler then
        local result = handler(target, index)
        if result ~= nil then return result end
    end

    error(`Unknown type, target, or index: {data_type}, {target}, {index}`)
end

local function write_component_value<T>(target: T, index: number, value: any): T
    root.assert(is_valid_data_type(target), "Invalid data type for writing component value.")

    local data_type = typeof(target) :: DataType
    local handler = write_handlers[data_type]
    
    if handler then
        return handler(target, index, value)
    else
        error(`Unknown type, target, or index: {data_type}, {target}, {index}`)
    end
end

local function get_component_count(value: any)
    root.assert(is_valid_data_type(value), "Invalid data type for getting component count.")

    local data_type = typeof(value) :: DataType
    return DATA_TYPE_SIZES[data_type]
end

local function get_default(category: string, item: string?)
    local result = DEFAULTS[category]
    if result and item ~= nil then
        result = (result :: any)[item]
    end
    return result
end

local function clip(value: number, places: number)
    local multiplier = 10 ^ places
    return math.floor(value * multiplier) / multiplier
end

local function apply_modifiers(value: number, options: InputOptions)
    local min = options.min or -math.huge
    local max = options.max or math.huge

    return math.clamp(value, min, max)
end

local function create_component_input(
    total_inputs: number, 
    value_source: source<number>,
    prefix: string, 
    options: InputOptions,
    on_change: (new_value: number) -> ()
)
    options = options or {} :: InputOptions
    local places = options.decimal_places
    local align = Enum.TextXAlignment:FromName(options.align or "Left")

    local function format_text(value: number)
        local result = value
        if places ~= nil then
            result = string.format(`%.{places}f`::any, result)
        end
        return `{prefix}{result}`
    end

    local active = root.source(false)
    local drag_connection: RBXScriptConnection?
    local ended_connection: RBXScriptConnection?

    local object = root.create("TextBox") {
        AutomaticSize = Enum.AutomaticSize.Y,
        ClearTextOnFocus = false,
        TextXAlignment = align,
        Size = UDim2.new(1 / total_inputs, 0, 0, 0),

        Text = format_text( value_source() ),
        Active = active,

        paint.text(),
        paint.background(),
        ui.flexitem("Shrink"),
        ui.padding(config.padding),

        Focused = function(self: TextBox)
            self.CursorPosition = #self.Text + 1
            self.SelectionStart = #prefix + 1
        end,

        FocusLost = function(self: TextBox)
            local text_to_parse = self.Text
            if prefix ~= "" and string.sub(text_to_parse, 1, #prefix) == prefix then
                text_to_parse = string.sub(self.Text, #prefix + 1)
            end
            
            local new_value = tonumber(text_to_parse)
            local places = options.decimal_places or FLOAT_PRECISION
            if new_value ~= nil and clip(new_value, places) == new_value then
                local modified_value = apply_modifiers(new_value, options)
                on_change(modified_value)
            end
            self.Text = format_text( value_source() )
        end,

        InputBegan = function(self: TextBox, input: InputObject)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if drag_connection ~= nil then return end
            if active() == true then return end

            self:ReleaseFocus()

			local start_position = input.Position
            local start_value = value_source()
            drag_connection = UserInputService.InputChanged:Connect(function(input: InputObject)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

				local delta = start_position - input.Position
                local dx = delta.X

                local places = options.decimal_places or FLOAT_PRECISION
                local new_value = clip(start_value - dx * 1/config.drag_sensitivity, places)
                local modified_value = apply_modifiers(new_value, options)
                on_change(modified_value)
            end)

            ended_connection = UserInputService.InputEnded:Connect(function(input: InputObject)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if drag_connection == nil then return end
                if ended_connection == nil then return end

                ended_connection:Disconnect()
                drag_connection:Disconnect()
                drag_connection = nil
            end)
        end,
    }

    active( not root.keys_pressed("LeftControl", "RightControl") )

    return {
        object = object,
    }
end

local function get_index(v: any, idx: number)
    if typeof(v) == "table" then
        return (v::any)[idx]
    end
    return v
end

local function create_data_type_inputs(value: root.value<any>, options: options?)
    local raw_value = root.read(value)

    local opt = root.default(options, {}) :: options
    local data_type = typeof(raw_value)
    local id = data_type .. (opt.suffix or "")

    local align_center = opt.align_center
    local min = opt.min or get_default("min", data_type)
    local max = opt.max or get_default("max", data_type)
    local step = opt.step or get_default("step", data_type)
    local decimal_places = opt.decimal_places or get_default("decimal_places", data_type)

    local component_count = get_component_count(raw_value)
    local prefixes = get_default("prefixes", id)

    local objects = {}
    local controls = {}
    local source = root.from(value)
    local changed = root.event()

    for idx = 1, component_count do
        local function on_component_change(new_component_value: number)
            local current_composite_value = source()
            local next_composite_value = write_component_value(current_composite_value, idx, new_component_value)
            source(next_composite_value)

            changed.fire()
        end

        local component_value_source = root.derive(function()
            return read_component_value(source(), idx) :: number
        end)
        
        local component_options: InputOptions = {
            align = if align_center then "Center" else "Left",
            decimal_places = get_index(decimal_places, idx),
            min = get_index(min, idx),
            max = get_index(max, idx),
            step = get_index(step, idx),
        }

        local input_control = create_component_input(
            component_count, 
            component_value_source, 
            prefixes[idx], 
            component_options, 
            on_component_change
        )

        controls[idx] = input_control
        objects[idx] = input_control.object

        root.mount(input_control.object)
    end

    return {
        objects = objects,
        changed = root.derive(changed.fired),
        value = source,
    }
end

local function create_button(
    text: string,
    on_click: (self: GuiObject, x: number, y: number) -> ()
)
    local clicked = root.event()
    local hovered = root.source(false)
    local object = root.create("TextLabel") {
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Center,

        paint.text(),
        paint.button(clicked.fired, hovered),

        ui.aspect_ratio(1),
        ui.hovered(hovered),
        ui.clicked("Button1", function(self, x, y)
            clicked.fire()
            on_click(self, x, y)
        end),
    } :: GuiObject

    if object.Parent and object.Parent:IsA("GuiObject") then
        local size = object.Parent.AbsoluteSize.Y
        object.Size = UDim2.fromOffset(size, size)
    end

    root.mount(object)
    return object
end

local function create_increment(
    value: source<number>,
    increment: number,
    on_change: ((incremented: boolean) -> ())?
)
    assert(increment > 0, "increment must be greater than 0")
    assert(is_valid_data_type(value()), "invalid datatype passed to create_increment")
    
    local add = create_button("+", function(self: GuiObject, x: number, y: number)
        local result = clip(value() + increment, FLOAT_PRECISION)
        value(result)

        if on_change then on_change(true) end
    end)

    local subtract = create_button("-", function(self: GuiObject, x: number, y: number)
        local result = clip(value() - increment, FLOAT_PRECISION)
        value(result)
        
        if on_change then on_change(false) end
    end)

    return root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,

        add,
        subtract,

        ui.flexitem("Shrink"),
        ui.padding(config.padding),
        ui.list_layout("Horizontal", config.spacing),
    }
end

local function create_color_preview(value: source<Color3>)
    local object = root.create("Frame") {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = value(),
    }

    root.mount(object)
    return object
end

return {
    read_component_value = read_component_value,
    write_component_value = write_component_value,
    get_component_count = get_component_count,
    create_component_input = create_component_input,
    DEFAULTS = DEFAULTS,
    is_valid_data_type = is_valid_data_type,
    get_default = get_default,
    create_data_type_inputs = create_data_type_inputs,
    create_increment = create_increment,
    create_color_preview = create_color_preview,
}

