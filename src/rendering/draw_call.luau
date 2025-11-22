local color4 = require("../datatypes/color4")
type color4 = color4.color4

export type draw_call_kind =
    | "rect"
    | "text"

type base_draw_call<T, kind = draw_call_kind> = {
    id: number,
    kind: kind,
} & T

export type draw_rect = base_draw_call<{
    position: vector,
    size: vector,
    color: color4,
}, "rect">

export type draw_text<Font = unknown> = base_draw_call<{
    position: vector,

    font: Font,
    text: string,
}, "text">

export type draw_call = draw_rect | draw_text

return {}