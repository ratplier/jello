local renderer = require("../rendering/renderer")
local draw_call = require("../rendering/draw_call")

local color4 = require("../datatypes/color4")
local rect = require("../datatypes/rect")

type color4 = color4.color4
type rect = rect.rect
type draw_call = draw_call.draw_call

type id = number
type data = {
    object: GuiObject,
    last_seen: number,
    [unknown]: unknown,
}

type renderer_state = {
    parent_stack: { GuiObject },
    data: { [id]: data },
    frame: number,

    root: ScreenGui,
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
                color4.component(value, 1),
                color4.component(value, 2),
                color4.component(value, 3)
            )
        elseif typeof(property_value) == "number" and type(value) == "buffer" then
            value = color4.component(value, 4)
        end

        --print(property, value)

        direct.write(instance, property, value)
    end
end

local function cleanup_entry(entry: data)
    entry.object:Destroy()
end

local function renew_entry(self: renderer_state, id: id, construct: () -> GuiObject)
    if not self.data[id] then
        self.data[id] = {
            object = construct(),
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

function resolver.rect(self: renderer_state, draw_call: draw_call.rect)
    local id = draw_call.id
    renew_entry(self, id, function()
        local frame = Instance.new("Frame")
        return frame
    end)

    local frame = self.data[id].object :: Frame

    local position = get_relative_position(self, draw_call.bounds.min)
    local size = draw_call.bounds.max - draw_call.bounds.min

    assign(frame, "Position", position)
    assign(frame, "Size", size)
    assign(frame, "BackgroundColor3", draw_call.color)

    assign(frame, "Parent", get_parent(self))
end

function resolver.clip(self: renderer_state, draw_call: draw_call.clip)
    local id = draw_call.id
    renew_entry(self, id, function()
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.ClipsDescendants = true
        return frame
    end)

    local frame = self.data[id].object :: Frame

    local position = get_relative_position(self, draw_call.bounds.min)
    local size = draw_call.bounds.max - draw_call.bounds.min

    assign(frame, "Position", position)
    assign(frame, "Size", size)
    assign(frame, "Parent", get_parent(self))

    table.insert(self.parent_stack, frame)
end

function resolver.end_clip(self: renderer_state, draw_call: draw_call.end_clip)
    table.remove(self.parent_stack)
end

local roblox = {}

function roblox.create_renderer_state(): renderer_state
    local self = {
        frame = 0,
        data = {},
        parent_stack = {},

        root = Instance.new("ScreenGui"),
    }

    self.root.Name = "jello_root"
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

function roblox.generate_renderer(self: renderer_state)
    return renderer.create(function(draw_calls)
        self.frame += 1

        for _, draw_call in draw_calls do
            if draw_call.kind == "rect" then
                resolver.rect(self, draw_call :: draw_call.rect)
            end
            
            if draw_call.kind == "clip" then
                resolver.clip(self, draw_call :: draw_call.clip)
            end
            
            if draw_call.kind == "end_clip" then
                resolver.end_clip(self, draw_call :: draw_call.end_clip)
            end
        end
        
        roblox.cleanup(self)
    end)
end

return roblox
