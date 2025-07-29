--!strict
local root = require("./rootkit")
local paint = require("./paint")
local ui = require("./uikit")
local config = require("../config")

export type datatype = "number" | "Vector2" | "Vector3" | "vector" | "UDim" | "UDim2" | "Color3" | "Color4" | "Rect"

local datatypes = {"number", "Vector2", "Vector3", "vector", "UDim", "UDim2", "Color3", "Color4", "Rect"}
local num_components = {
    number = 1,
    Vector2 = 2,
    Vector3 = 3,
    vector = 3,
    UDim = 2,
    UDim2 = 4,
    Color3 = 3,
    Color4 = 4,
    Rect = 4,
}

local read_handlers = {
    number = function(v, i) return v end,
    Vector2 = function(v, i) return i == 0 and v.X or v.Y end,
    Vector3 = function(v, i) return i == 0 and v.X or i == 1 and v.Y or v.Z end,
    vector = function(v, i) return i == 0 and v.x or i == 1 and v.y or v.z end,
    UDim = function(v, i) return i == 0 and v.Scale or v.Offset end,
    UDim2 = function(v, i) return i == 0 and v.X.Scale or i == 1 and v.X.Offset or i == 2 and v.Y.Scale or v.Y.Offset end,
    Rect = function(v, i) return i == 0 and v.Min.X or i == 1 and v.Min.Y or i == 2 and v.Max.X or v.Max.Y end,
    table = function(v, i) return v[i] end,

    Color3 = function(v: Color3, i) local r,g,b=v.R,v.G,v.B; return i == 0 and r * 255 or i == 1 and g * 255 or b * 255 end,
    Color4 = function(v, i) return buffer.readu8(v :: buffer, i) end,
} :: {[datatype]: (any, number) -> any}

local write_handlers = {
    number = function(v, i, value) return value end,
    Vector2 = function(v, i, value) return (i == 0 and Vector2.new(value, v.Y) or i == 1 and Vector2.new(v.X, value) or error("Invalid index for Vector2 type")) end,
    Vector3 = function(v, i, value) return (i == 0 and Vector3.new(value, v.Y, v.Z) or i == 1 and Vector3.new(v.X, value, v.Z) or i == 2 and Vector3.new(v.X, v.Y, value) or error("Invalid index for Vector3 type")) end,
    vector = function(v, i, value) return (i == 0 and {x = value, y = v.y, z = v.z} or i == 1 and {x = v.x, y = value, z = v.z} or i == 2 and {x = v.x, y = v.y, z = value} or error("Invalid index for vector type")) end,
    UDim = function(v, i, value) return (i == 0 and UDim.new(value, v.Offset) or i == 1 and UDim.new(v.Scale, value) or error("Invalid index for UDim type")) end,
    UDim2 = function(v, i, value) return (i == 0 and UDim2.new(value, v.X.Offset, v.Y.Scale, v.Y.Offset) or i == 1 and UDim2.new(v.X.Scale, value, v.Y.Scale, v.Y.Offset) or i == 2 and UDim2.new(v.X.Scale, v.X.Offset, value, v.Y.Offset) or i == 3 and UDim2.new(v.X.Scale, v.X.Offset, v.Y.Scale, value) or error("Invalid index for UDim2 type")) end,
    Rect = function(v, i, value) return (i == 0 and Rect.new(value, v.Min.Y, v.Max.X, v.Max.Y) or i == 1 and Rect.new(v.Min.X, value, v.Max.X, v.Max.Y) or i == 2 and Rect.new(v.Min.X, v.Min.Y, value, v.Max.Y) or i == 3 and Rect.new(v.Min.X, v.Min.Y, v.Max.X, value) or error("Invalid index for Rect type")) end,
    table = function(v, i, value) v[i] = value; return v end,

    Color3 = function(v, i, value) return (i == 0 and Color3.fromRGB(value, v.G, v.B) or i == 1 and Color3.fromRGB(v.R, value, v.B) or i == 2 and Color3.fromRGB(v.R, v.G, value) or error("Invalid index for Color3 type")) end,
    Color4 = function(v, i, value) return buffer.writeu8(v :: buffer, i, value) end,
} :: {[datatype]: (any, number, any) -> any}

local defaults = {
    default_min = {
        number = { 0 },
        Vector2 = { 0, 0 },
        Vector3 = { 0, 0, 0 },
        vector = { 0, 0, 0 },
        UDim = { 0, 0 },
        UDim2 = { 0, 0, 0, 0 },
        Rect = { 0, 0, 0, 0 },
    },
    default_max = {
        number = { 100 },
        Vector2 = { 100, 100 },
        Vector3 = { 100, 100, 100 },
        vector = { 100, 100, 100 },
        UDim = { 1, 1000 },
        UDim2 = { 1, 1000, 1, 1000 },
        Rect = { 1000, 1000, 1000, 1000 },
    },
    prefixes = {
        number = { "" },
        Vector2 = { "x: ", "y: " },
        Vector3 = { "x: ", "y: ", "z: " },
        vector = { "x: ", "y: ", "z: " },
        UDim = { "", "" },
        UDim2 = { "", "", "", "" },
        Color3 = { "r: ", "g: ", "b: " },
        Color4 = { "r: ", "g: ", "b: ", "a: " },
        Rect = { "mx: ", "my: ", "Mx: ", "My: " },
    },
    default_degrees = {
        number = { 0 },
        Vector2 = { 0, 0 },
        Vector3 = { 0, 0, 0 },
        vector = { 0, 0, 0 },
        UDim = { 3, 0 },
        UDim2 = { 3, 0, 3, 0 },
        Color3 = { 0, 0, 0 },
        Color4 = { 0, 0, 0, 0 },
        Rect = { 0, 0, 0, 0 },
    }
}

local function valid_datatype(value: any)
    local type = typeof(value) :: datatype
    return table.find(datatypes, type) ~= nil
end

local function read_index<T>(target: T, index: number): number?
    root.assert(valid_datatype(target), "invalid datatype")

    local type = typeof(target)
    local handler = read_handlers[type :: datatype]

    if handler then
        local result = handler(target, index)
        if result ~= nil then return result end
    end

    error(`unknown type, target or index {type}, {target}, {index}`)
end

local function write_index<T>(target: T, index: number, value: any)
    root.assert(valid_datatype(target), "invalid datatype")

    local type = typeof(target) :: datatype
    local handler = write_handlers[type]
    
    if handler then
        handler(target, index, value)
    else
        error(`unknown type, target or index {type}, {target}, {index}`)
    end
end

local function size(value: any)
    root.assert(valid_datatype(value), "invalid datatype")

    local type = typeof(value) :: datatype
    return num_components[type]
end

export type options = {
    align: ("Left" | "Center" | "Right")?,
    decimal_places: number?,
    min: number?,
    max: number?,
    step: number?,
}

local function apply_modifiers(value: number, options: options)
    local min = options.min or -math.huge
    local max = options.max or math.huge
    local step = options.step

    local number = math.clamp(value, min, max)

    if step ~= nil then
        number = math.round(number / step) * step
    end
    return number
end

local function create_input(total: number, value: number, prefix: string, options: options)
    options = options or {} :: options
    local places = options.decimal_places
    local align = Enum.TextXAlignment:FromName(options.align or "Left")

    local raw_n = root.source( apply_modifiers(value, options) )
    local format_text = function()
        local result = raw_n()
        if places ~= nil then
            result = string.format(`%.{places}f`::any, result)
        end
        return `{prefix}{result}`
    end

    return root.create("TextBox") {
        AutomaticSize = Enum.AutomaticSize.Y,
        ClearTextOnFocus = false,

        Text = format_text(),
        TextXAlignment = align,
        Size = UDim2.new(1/total, 0, 0, 0),

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
            
            local new_value = tonumber(text_to_parse) or raw_n()
            raw_n( apply_modifiers(new_value, options) )
            self.Text = format_text()
        end,
    }
end

local function get_default(path: string, value: any)
    local parts = string.split(path, "/")
    local result = defaults
    for _, part in parts do
        result = result[part]
    end

    return (result::any)[typeof(value)]
end

return {
    read_index = read_index,
    write_index = write_index,
    size = size,
    create_input = create_input,
    defaults = defaults,
    valid_datatype = valid_datatype,
    get_default = get_default,
}