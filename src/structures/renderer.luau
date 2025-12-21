local rgba = require("../datatypes/rgba")
local aabb = require("../datatypes/aabb")

type aabb = aabb.aabb
type rgba = rgba.rgba

export type rect = {
    kind: "rect",
    bounds: aabb,
    color: rgba,
}

export type clip = {
    kind: "clip",
    bounds: aabb,
}

export type end_clip = {
    kind: "end_clip",
}

export type text_alignment = "left" | "center" | "right"
export type text<font = unknown> = {
    kind: "text",
    font: font,
    
    text: string,
    bounds: aabb,
    color: rgba,
    
    size: number,
    align: text_alignment,
    wrap: boolean,
}

export type draw_call = rect | clip | end_clip | text

export type dispatch = (draw_calls: { draw_call }) -> ()
export type renderer = {
    draw_calls: { draw_call },
    dispatch_callback: dispatch,
    
    push: (self: renderer, draw_call: draw_call) -> (),
    dispatch: (self: renderer) -> (),
}

local renderer = {}

function renderer.create(dispatch: dispatch): renderer
    local self = {
        draw_calls = {},
        dispatch_callback = dispatch,
    }

    self.push = renderer.push
    self.dispatch = renderer.dispatch
    return self
end

function renderer.push(self: renderer, call: draw_call)
    table.insert(self.draw_calls, call)
end

function renderer.dispatch(self: renderer)
    self.dispatch_callback(self.draw_calls)
    table.clear(self.draw_calls)
end

return renderer