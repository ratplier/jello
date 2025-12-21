local renderer = require("../structures/renderer")
local input_state = require("../structures/input_state")

local rgba = require("../datatypes/rgba")
local aabb = require("../datatypes/aabb")

type color4 = rgba.rgba
type rect = aabb.aabb
type draw_call = renderer.draw_call

type id = number
type data = {
    object: GuiObject,
    last_seen: number,
    class: string,
}

type renderer_state = {
    parent_stack: { GuiObject },
    data: { [id]: data },
    pool: { [string]: {GuiObject} },
    frame: number,
    root: ScreenGui,

    renderer: renderer.renderer,
    input_state: input_state.input_state,
}

local direct = {} do
    local _, write = xpcall(function()
        (workspace::any).Parent = nil
        return (nil::any) :: (Instance, string, unknown) -> ()
    end, function()
        return debug.info(2, "f")
    end)

    local _, read = xpcall(function()
        return ((workspace::any)[nil]) :: (Instance, string) -> unknown
    end, function()
        return debug.info(2, "f")
    end)

    direct.write = write
    direct.read = read
end

local function assign(instance: Instance, property: string, value: unknown)
    local property_value = direct.read(instance, property)
    
    if property_value ~= value then    
        if typeof(property_value) == "UDim2" and type(value) == "vector" then
            value = UDim2.fromOffset(value.x, value.y)
        elseif typeof(property_value) == "Color3" and type(value) == "buffer" then
            value = Color3.new(
                rgba.component(value, "r"),
                rgba.component(value, "g"),
                rgba.component(value, "b")
            )
        elseif typeof(property_value) == "number" and type(value) == "buffer" then
            value = rgba.component(value, "a")
        end

        direct.write(instance, property, value)
    end
end

local function cleanup_entry(entry: data)
    entry.object:Destroy()
end

local function fetch_instance(self: renderer_state, class: string): GuiObject
    local class_pool = self.pool[class]
    if class_pool and #class_pool > 0 then
        local obj = table.remove(class_pool) :: GuiObject
        obj.Visible = true
        return obj
    end

    local obj = Instance.new(class) :: any
    if class == "Frame" then
        obj.BorderSizePixel = 0
    elseif class == "TextLabel" then
        obj.BackgroundTransparency = 1
        obj.BorderSizePixel = 0
    end
    return obj
end

local function renew_entry(self: renderer_state, id: id, class: string)
    local existing = self.data[id]
    
    if existing and existing.class ~= class then
        existing.object.Visible = false
        existing.object.Parent = nil

        table.insert(self.pool[existing.class], existing.object)
        self.data[id] = nil
    end

    if not self.data[id] then
        if not self.pool[class] then self.pool[class] = {} end
        
        self.data[id] = {
            object = fetch_instance(self, class),
            class = class,
            last_seen = self.frame,
        }
    end

    self.data[id].last_seen = self.frame
end

local function get_parent(self: renderer_state)
    return self.parent_stack[#self.parent_stack] or self.root
end

local function get_relative_position(self: renderer_state, position: vector)
    local abs = get_parent(self).AbsolutePosition
    return position - vector.create(abs.X, abs.Y)
end

local resolver = {}

function resolver.rect(self: renderer_state, id: id, draw_call: renderer.rect)
    renew_entry(self, id, "Frame")
    local frame = self.data[id].object :: Frame

    local position = get_relative_position(self, draw_call.bounds.min)
    local size = draw_call.bounds.max - draw_call.bounds.min

    assign(frame, "Position", position)
    assign(frame, "Size", size)
    assign(frame, "BackgroundColor3", draw_call.color)

    assign(frame, "Parent", get_parent(self))
end

function resolver.clip(self: renderer_state, id: id, draw_call: renderer.clip)
    renew_entry(self, id, "Frame")
    local frame = self.data[id].object :: Frame

    local position = get_relative_position(self, draw_call.bounds.min)
    local size = draw_call.bounds.max - draw_call.bounds.min

    assign(frame, "Position", position)
    assign(frame, "Size", size)
    assign(frame, "ClipsDescendants", true)
    assign(frame, "Parent", get_parent(self))

    table.insert(self.parent_stack, frame)
end

function resolver.end_clip(self: renderer_state, id: id, draw_call: renderer.end_clip)
    table.remove(self.parent_stack)
end

function resolver.text(self: renderer_state, id: id, draw_call: renderer.text<Enum.Font>)
    renew_entry(self, id, "TextLabel")
    local label = self.data[id].object :: TextLabel

    local position = get_relative_position(self, draw_call.bounds.min)
    local size = draw_call.bounds.max - draw_call.bounds.min

    assign(label, "Position", position)
    assign(label, "Size", size)
    assign(label, "Text", draw_call.text)
    assign(label, "TextColor3", draw_call.color)
    assign(label, "TextSize", draw_call.size)
    assign(label, "TextWrapped", draw_call.wrap)
    assign(label, "TextXAlignment",
        if draw_call.align == "left" then Enum.TextXAlignment.Left
        elseif draw_call.align == "center" then Enum.TextXAlignment.Center
        else Enum.TextXAlignment.Right
    )
    assign(label, "FontFace", Font.fromEnum(
        draw_call.font
    ))

    assign(label, "Parent", get_parent(self))
end

local roblox = {}

local function generate_renderer(self: renderer_state)
    return renderer.create(function(draw_calls)
        local id = 0
        self.frame += 1

        for _, draw_call in draw_calls do
            if draw_call.kind == "rect" then
                resolver.rect(self, id, draw_call)
            elseif draw_call.kind == "clip" then
                resolver.clip(self, id, draw_call)
            elseif draw_call.kind == "end_clip" then
                resolver.end_clip(self, id, draw_call)
            elseif draw_call.kind == "text" then
                resolver.text(self, id, draw_call :: renderer.text<Enum.Font>)
            end

            id += 1
        end
        
        roblox.cleanup(self)
    end)
end

local K = Enum.KeyCode
local key_to_input = {
    -- Alphabet
    [K.A]="a",[K.B]="b",[K.C]="c",[K.D]="d",[K.E]="e",[K.F]="f",[K.G]="g",[K.H]="h",[K.I]="i",
    [K.J]="j",[K.K]="k",[K.L]="l",[K.M]="m",[K.N]="n",[K.O]="o",[K.P]="p",[K.Q]="q",[K.R]="r",
    [K.S]="s",[K.T]="t",[K.U]="u",[K.V]="v",[K.W]="w",[K.X]="x",[K.Y]="y",[K.Z]="z",

    -- Numbers
    [K.Zero]="zero",[K.One]="one",[K.Two]="two",[K.Three]="three",[K.Four]="four",
    [K.Five]="five",[K.Six]="six",[K.Seven]="seven",[K.Eight]="eight",[K.Nine]="nine",

    -- Symbols
    [K.Space]="space",[K.Quote]="apostrophe",[K.Comma]="comma",[K.Minus]="minus",
    [K.Period]="period",[K.Slash]="slash",[K.Semicolon]="semicolon",[K.Equals]="equal",
    [K.LeftBracket]="left_bracket",[K.RightBracket]="right_bracket",[K.BackSlash]="backslash",
    [K.Backquote]="grave_accent",[K.Tilde]="tilde",

    -- Control
    [K.Return]="enter",[K.Tab]="tab",[K.Backspace]="backspace",[K.Escape]="escape",
    [K.LeftShift]="left_shift", [K.RightShift]="right_shift",
    [K.LeftControl]="left_control", [K.RightControl]="right_control",
    [K.LeftAlt]="left_alt", [K.RightAlt]="right_alt"
}

local function generate_input_state()
    local UserInputService = game:GetService("UserInputService")
    
    return input_state.new(function(self: input_state.input_state, set_state)
        local function create_helper(state: boolean)
            return function(input_object: InputObject)
                local key_code = input_object.KeyCode
                local mapped = key_to_input[key_code] :: input_state.input

                if mapped then
                    set_state(mapped, state)
                end

                if input_object.UserInputType == Enum.UserInputType.MouseButton1 then
                    set_state("mouse1", state)
                end
                if input_object.UserInputType == Enum.UserInputType.MouseButton2 then
                    set_state("mouse2", state)
                end
                if input_object.UserInputType == Enum.UserInputType.MouseButton3 then
                    set_state("mouse3", state)
                end

                if input_object.UserInputType == Enum.UserInputType.MouseWheel then
                    self.scroll_delta = input_object.Position.Z
                end
            end
        end

        UserInputService.InputBegan:Connect(create_helper(true))
        UserInputService.InputEnded:Connect(create_helper(false))

        UserInputService.InputChanged:Connect(function(object)
            local pos = vector.create(object.Position.X, object.Position.Y)
            local delta = self.mouse_position - pos

            self.mouse_position = pos
            self.mouse_delta = delta
        end)
    end)
end

function roblox.create_state(): renderer_state
    local root = Instance.new("ScreenGui")
    root.Name = "jello_root"
    root.IgnoreGuiInset = true

    local self = {
        frame = 0,
        data = {},
        parent_stack = {},
        pool = {},

        root = root,
    }

    self.renderer = generate_renderer(self)
    self.input_state =  generate_input_state()
    return self
end

function roblox.cleanup(self: renderer_state)
    for id, entry in self.data do
        if entry.last_seen ~= self.frame then
            cleanup_entry(entry)
            
            self.data[id] = nil
        end
    end
end

return roblox
