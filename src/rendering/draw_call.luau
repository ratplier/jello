local color4 = require("../datatypes/color4")
local rect = require("../datatypes/rect")

type bounds = rect.rect
type color4 = color4.color4

export type draw_call_kind =
    | "rect"
    | "clip"
    | "end_clip"
    | "text"

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

export type text_alignment = "left" | "center" | "right"
export type text<font = unknown> = {
    kind: "text",
    id: number,

    font: font,
    
    text: string,
    bounds: bounds,
    color: color4,
    
    size: number,
    align: text_alignment,
    wrap: boolean,
}

export type draw_call =
    | rect
    | clip
    | end_clip
    | text

local assert = {}

function assert.is_draw_call_kind(value: unknown): boolean
    return (
        type(value) == "string" and
        (
            value == "rect" or
            value == "clip" or
            value == "end_clip" or
            value == "text"
        )
    )
end

function assert.is_draw_call(value: unknown): boolean
    if type(value) ~= "table" then
        return false
    end

    local draw_call = value :: draw_call
    return (
        type(draw_call.id) == "number" and
        type(draw_call.kind) == "string" and
        assert.is_draw_call_kind(draw_call.kind)
    )
end

function assert.is_rect(value: unknown): boolean
    if not assert.is_draw_call(value) then
        return false
    end

    local draw_call = value :: rect
    return (
        draw_call.kind == "rect" and
        rect.is_rect(draw_call.bounds) and
        color4.is_color4(draw_call.color)
    )
end

function assert.is_clip(value: unknown): boolean
    if not assert.is_draw_call(value) then
        return false
    end

    local draw_call = value :: clip
    return (
        draw_call.kind == "clip" and
        rect.is_rect(draw_call.bounds)
    )
end

function assert.is_end_clip(value: unknown): boolean
    if not assert.is_draw_call(value) then
        return false
    end

    local draw_call = value :: end_clip
    return draw_call.kind == "end_clip"
end

function assert.is_text(value: unknown): boolean
    if not assert.is_draw_call(value) then
        return false
    end

    local draw_call = value :: text
    return (
        draw_call.kind == "text" and
        rect.is_rect(draw_call.bounds) and
        color4.is_color4(draw_call.color) and

        type(draw_call.text) == "string" and
        type(draw_call.font) == "string" and
        type(draw_call.size) == "number" and
        type(draw_call.align) == "string" and   
        type(draw_call.wrap) == "boolean"
    )
end

return assert