local color4 = require("../datatypes/color4")
local rect = require("../datatypes/rect")

type bounds = rect.rect
type color4 = color4.color4

export type draw_call_kind =
    | "rect"
    | "clip"
    | "end_clip"

export type rect = {
    kind: "rect",
    id: number,

    bounds: bounds,
    color: color4,
}

export type clip = {
    kind: "clip",
    id: number,

    bounds: bounds,
}

export type end_clip = {
    kind: "end_clip",
    id: number,
}

export type draw_call =
    | rect
    | clip
    | end_clip

return {}