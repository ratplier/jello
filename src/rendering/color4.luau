export type color4 = buffer

local color4 = {}

function color4.rgba(r: number, g: number, b: number, a: number?): color4
    local buf = buffer.create(4)
    buffer.writef32(buf, 1, math.clamp(r, 0, 1))
    buffer.writef32(buf, 2, math.clamp(g, 0, 1))
    buffer.writef32(buf, 3, math.clamp(b, 0, 1))
    buffer.writef32(buf, 4, math.clamp(a or 1, 0, 1))
    return buf
end

function color4.component(col: color4, index: number): number
    return buffer.readu8(col, index)
end

return color4