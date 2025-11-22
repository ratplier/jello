local draw_call = require("./draw_call")

type draw_call = draw_call.draw_call
type draw_call_kind = draw_call.draw_call_kind

export type dispatch_fn = (draw_calls: { draw_call }) -> ()
export type renderer = {
    draw_calls: { draw_call },
    dispatch_callback: dispatch_fn,
    
    push: (self: renderer, draw_call: draw_call) -> (),
    dispatch: (self: renderer) -> (),
}

local renderer = {}

function renderer.create(dispatch: dispatch_fn): renderer
    local self = {
        draw_calls = {},
        dispatch_callback = dispatch,
    }

    self.push = renderer.push
    self.dispatch = renderer.dispatch
    return self
end

function renderer.push(self: renderer, draw_call: draw_call)
    table.insert(self.draw_calls, draw_call)
end

function renderer.dispatch(self: renderer)
    self.dispatch_callback(self.draw_calls)
    table.clear(self.draw_calls)
end

return renderer