local color4 = require("../datatypes/color4")
local rect = require("../datatypes/rect")

type bounds = rect.rect
type color4 = color4.color4

export type draw_call_kind =
    | "rect"

type call<T, kind = draw_call_kind> = {
    id: number,
    kind: kind,
} & T

export type rect = call<{
    bounds: bounds,
    color: color4,
}, "rect">

export type draw_call = rect

return {}