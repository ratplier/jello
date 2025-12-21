export type rgba = buffer

local INDEX_MAP = { r = 0, g = 1, b = 2, a = 3, }
local rgba = {}

function rgba.create(r: number?, g: number?, b: number?, a: number?): rgba
    local buf = buffer.create(16)
    buffer.writef32(buf, INDEX_MAP.r * 4, math.clamp(r or 1, 0, 1))
    buffer.writef32(buf, INDEX_MAP.g * 4, math.clamp(g or 1, 0, 1))
    buffer.writef32(buf, INDEX_MAP.b * 4, math.clamp(b or 1, 0, 1))
    buffer.writef32(buf, INDEX_MAP.a * 4, math.clamp(a or 1, 0, 1))
    return buf
end

function rgba.from_rgba255(r: number?, g: number?, b: number?, a: number?)
    if r then r /= 255 end
    if g then g /= 255 end
    if b then b /= 255 end
    return rgba.create(r, g, b, a)
end

function rgba.tostring(col: rgba)
    local r = rgba.component(col, "r")
    local g = rgba.component(col, "g")
    local b = rgba.component(col, "b")
    local a = rgba.component(col, "a")

    return `rgba({r}, {g}, {b}, {a})`
end

function rgba.component(col: rgba, index: "r" | "g" | "b" | "a"): number
    return buffer.readf32(col, INDEX_MAP[index] * 4)
end

function rgba.is(value: unknown): boolean
    return type(value) == "buffer" and buffer.len(value) == 16
end

return rgba