local renderer = require("../rendering/renderer")
local color4 = require("../datatypes/color4")
local draw_call = require("../rendering/draw_call")

type color4 = color4.color4

type draw_call = draw_call.draw_call
type draw_rect = draw_call.draw_rect
type draw_text = draw_call.draw_text

type id = number
type data = {
    object: GuiObject,
    [unknown]: unknown,
}

type renderer_state = {
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

local function assign<T>(instance: T, property: string, value: unknown)
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

local resolver = {}

function resolver.rect(self: renderer_state, draw_call: draw_rect)
    local id = draw_call.id
    renew_entry(self, id, function()
        local frame = Instance.new("Frame")
        return frame
    end)

    local frame = self.data[id].object :: Frame

    assign(frame, "BackgroundColor3", draw_call.color)
    assign(frame, "Position", draw_call.bounds.min)
    assign(frame, "Size", draw_call.bounds.max - draw_call.bounds.min)
    assign(frame, "Parent", self.root)
end

local roblox = {}

function roblox.create_renderer_state(): renderer_state
    local self = {
        frame = 0,
        data = {},

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

function roblox.create_renderer(self: renderer_state)
    return renderer.create(function(draw_calls)
        self.frame += 1

        for _, draw_call in draw_calls do
            if draw_call.kind == "rect" then
                resolver.rect(self, draw_call)
            end
        end
        
        roblox.cleanup(self)
    end)
end

return roblox
