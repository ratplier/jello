export type color4 = buffer

local color4 = {}

function color4.rgba(r: number?, g: number?, b: number?, a: number?): color4
    local buf = buffer.create(16)
    buffer.writef32(buf, 0, math.clamp(r or 1, 0, 1))
    buffer.writef32(buf, 4, math.clamp(g or 1, 0, 1))
    buffer.writef32(buf, 8, math.clamp(b or 1, 0, 1))
    buffer.writef32(buf, 12, math.clamp(a or 1, 0, 1))
    return buf
end

function color4.tostring(col: color4)
    local r = color4.component(col, 1)
    local g = color4.component(col, 2)
    local b = color4.component(col, 3)
    local a = color4.component(col, 4)

    return `color4({r}, {g}, {b}, {a})`
end

function color4.component(col: color4, index: number): number
    return buffer.readf32(col, (index - 1) * 4)
end

function color4.is_color4(value: unknown): boolean
    return type(value) == "buffer" and buffer.len(value) == 16
end

return color4