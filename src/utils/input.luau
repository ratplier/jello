--!strict
local UserInputService = game:GetService("UserInputService")

local root = require("./rootkit")
local paint = require("./paint")
local ui = require("./uikit")
local config = require("../config")

local row = require("../widgets/format/row")

type source<T> = root.source<T>
type value<T> = root.value<T>

export type DataType = "number" | "Vector2" | "Vector3" | "vector" | "UDim" | "UDim2" | "Color3" | "buffer" | "Rect" | string
export type options = {
    prefix: string?,
    align: ("Left" | "Center" | "Right")?,

    id_suffix: string?,

    min: number?,
    max: number?,
    increment: number?,
    decimal_places: number?,

    has_buttons: boolean?,
    has_color_preview: boolean?,
}

local DATA_TYPES = {"number", "Vector2", "Vector3", "vector", "UDim", "UDim2", "Color3", "buffer", "Rect"}
local DATA_TYPE_SIZES = { number = 1, Vector2 = 2, Vector3 = 3, vector = 3, UDim = 2, UDim2 = 4, Color3 = 3, buffer = 4, Rect = 4 }
local FLOAT_PRECISION = 12

local CONTAINER_WIDTH = 0.65
local BUTTON_SIZE = config.rowHeight + config.padding

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
    vector = function(vec: vector, index: number): number
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
    Color3_HSV = function(color: Color3, index: number): number
        local h, s, v = color:ToHSV()
        if index == 1 then return h * 255 end
        if index == 2 then return s * 255 end
        if index == 3 then return v * 255 end
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
    vector = function(target: vector, index: number, value: number): {x: number, y: number, z: number}
        if index == 1 then return vector.create(value, target.y, target.z) end
        if index == 2 then return vector.create(target.x, value, target.z) end
        if index == 3 then return vector.create(target.x, target.y, value) end
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
    Color3_HSV = function(target: Color3, index: number, value: number): Color3
        local h, s, v = target:ToHSV()
        if index == 1 then return Color3.fromHSV(value/255, s, v) end
        if index == 2 then return Color3.fromHSV(h, value/255, v) end
        if index == 3 then return Color3.fromHSV(h, s, value/255) end
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
        Color3_HSV = { "h: ", "s: ", "v: " },
        --buffer = { "r: ", "g: ", "b: ", "a: " }, -- color4
        Rect = { "", "", "", "" },
    },
    decimal_places = {
        number = { nil },
        Vector2 = { nil, nil },
        Vector3 = { nil, nil, nil },
        vector = { nil, nil, nil },
        UDim = { 3, 0 },
        UDim2 = { 3, 0, 3, 0 },
        Color3 = { 0, 0, 0 },
        --buffer = { 0, 0, 0, 0 }, -- Color4
        Rect = { nil, nil, nil, nil },
    },
}

local function is_valid_data_type(value: any)
    return table.find(DATA_TYPES, typeof(value)) ~= nil
end

local function read_component_value<T>(target: T, index: number, suffix: string?): number?
    root.assert(is_valid_data_type(target), "Invalid data type for reading component value.")

    local suf = suffix or ""
    local data_type = typeof(target) :: DataType
    local handler = read_handlers[data_type .. suf]

    if handler then
        local result = handler(target, index)
        if result ~= nil then return result end
    end

    error(`Unknown type, target, or index: {data_type}, {target}, {index}`)
end

local function write_component_value<T>(target: T, index: number, value: any, suffix: string?): T
    root.assert(is_valid_data_type(target), "Invalid data type for writing component value.")

    local suf = suffix or ""
    local data_type = typeof(target) :: DataType
    local handler = write_handlers[data_type .. suf]

    if handler then
        return handler(target, index, value)
    else
        error(`Unknown type, target, or index: {data_type}, {target}, {index}`)
    end
end

local function get_component_count(value: any): number
    root.assert(is_valid_data_type(value), "Invalid data type for getting component count.")

    local data_type = typeof(value) :: DataType
    return DATA_TYPE_SIZES[data_type]
end

local function get_default(category: string, item: string?)
    local result = DEFAULTS[category]
    if result ~= nil and item ~= nil then
        result = (result::any)[item]
    end
    return result
end

local function clip(value: number, places: number)
    local multiplier = 10 ^ places
    return math.floor(value * multiplier) / multiplier
end

local function apply_modifiers(value: number, options: options)
    local min = options.min or -math.huge
    local max = options.max or math.huge

    return math.clamp(value, min, max)
end

local function create_input_component(
    width: UDim,
    value_source: source<number>,
    options: options,
    on_change: (new_value: number) -> ()
)
    options = options or {} :: options
    local places = options.decimal_places
    local align = Enum.TextXAlignment:FromName(options.align or "Left")

    local function format_text()
        local result = value_source()
        if places ~= nil then
            result = string.format(`%.{places}f`::any, result)
        end
        return `{options.prefix}{result}`
    end

    local active = root.source(false)
    local prefix = options.prefix :: string
    local drag_connection: RBXScriptConnection?
    local ended_connection: RBXScriptConnection?

    local object = root.create("TextBox") {
        function(self: TextBox)
            active( not root.keys_pressed("LeftControl", "RightControl") )
        end,

        AutomaticSize = Enum.AutomaticSize.Y,
        ClearTextOnFocus = false,
        TextXAlignment = align,

        Active = active,
        Text = format_text,
        Size = function()
            return UDim2.new( width, UDim.new(0, 0) )
        end,

        paint.text(),
        paint.background(),
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
            else
                self.Text = format_text()
            end
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
                ended_connection = nil
            end)
        end,
    }

    return {
        object = object,
    }
end

local function create_button(
    text: string,
    on_click: (self: GuiObject, x: number, y: number) -> ()
)
    local clicked = root.event()
    local hovered = root.source(false)
    local object = root.create("TextLabel") {
        Active = true,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),

        paint.text(),
        paint.button(clicked.fired, hovered),

        ui.hovered(hovered),
        ui.clicked("Button1", function(self, x, y)
            clicked.fire()
            on_click(self, x, y)
        end),
    } :: GuiObject

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
        add, subtract,

        ui.padding(config.padding),
        ui.list_layout("Horizontal", config.spacing),
    }
end

local function create_color_preview(value: value<Color3>, transparency: value<number>?)
    local t = transparency or 0
    local object = root.create("Frame") {
        Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        BackgroundColor3 = root.read(value),
        BackgroundTransparency = root.read(t),
    } :: Frame

    root.mount(object)
    return object
end

local function get_index(v: any, idx: number)
    if typeof(v) == "table" then
        return (v::any)[idx]
    end
    return v
end

local function get_component_offset(increment: boolean?, color_preview: boolean?)
    local button_count = 0
    if increment then button_count += 2 end
    if color_preview then button_count += 1 end
    return (BUTTON_SIZE + config.spacing) * button_count
end

local function create_data_type_inputs(value: root.value<any>, options: options?)
    local raw_value = root.read(value)
    local data_type = typeof(raw_value)

    local opt = root.default(options, {}) :: options
    local id = data_type .. (opt.id_suffix or "")

    local prefixes = opt.prefix or get_default("prefixes", id)
    local min = opt.min or get_default("min", data_type)
    local max = opt.max or get_default("max", data_type)
    local increment = opt.increment or get_default("increment", data_type)
    local decimal_places = opt.decimal_places or get_default("decimal_places", data_type)

    local component_count = get_component_count(raw_value)
    local component_offset = get_component_offset(opt.has_buttons, opt.has_color_preview)
    local component_width = UDim.new(
        CONTAINER_WIDTH / component_count,
        - (config.spacing + (component_offset / component_count))
    )

    local components = {}
    local target_source = root.from(value)
    local changed = root.event()

    for i = 1, component_count do
        local raw_component_value = read_component_value(raw_value, i)
        local component_value = root.from(raw_component_value) :: source<number>

        local function component_changed(new_value: any)
            local value = write_component_value(raw_value, i, new_value)
            component_value(new_value)
            target_source(value)
            changed.fire()
        end
        
        local component_options = {
            align = if opt.align then opt.align else "Left",
            min = min, max = max, increment = increment,
            prefix = get_index(prefixes, i),
            decimal_places = get_index(decimal_places, i),

            id_suffix = opt.id_suffix,
            has_buttons = opt.has_buttons,
            has_color_preview = opt.has_color_preview,
        }

        local object = create_input_component(
            component_width, component_value, component_options, component_changed
        ).object
        root.mount(object)

        components[i] = {
            object = object,
            value = component_value,
        }
        
    end

    if opt.has_buttons then
        local src = components[1].value
        create_increment(src, increment, function(incremented)
            changed.fire()
        end)
    end

    if opt.has_color_preview then
        local src = target_source :: source<Color3>
        create_color_preview(src)
    end
    
    return {
        changed = root.derive(changed.fired),
        value = target_source,
    }
end

local function create_input_label(text: string)
    root.mount(function()
        return root.create("TextLabel") {
            Text = text,
            AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Left,

            Size = UDim2.fromScale(1, 0),

            paint.text(),
            paint.no_background(),

            ui.flexitem("Shrink"),
        }
    end)
end

local function get_decimal_places(n: number)
	local s = tostring(n)
    local l = s:len()
	local i = s:find("%.") or l
	return l - i
end

return {
    DEFAULTS = DEFAULTS,

    row = row,
    get_decimal_places = get_decimal_places,

    read_component_value = read_component_value,
    write_component_value = write_component_value,
    get_component_count = get_component_count,
    create_input_component = create_input_component,
    is_valid_data_type = is_valid_data_type,
    get_default = get_default,
    create_data_type_inputs = create_data_type_inputs,
    create_increment = create_increment,
    create_color_preview = create_color_preview,
    create_input_label = create_input_label,
}

