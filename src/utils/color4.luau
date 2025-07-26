--!strict
local color4 = {}

export type color4 = buffer

function color4.create(r: number?, g: number?, b: number?, a: number?): color4
	r, g, b, a = r or 0, g or 0, b or 0, a or 1

	local color = buffer.create(4)
	buffer.writeu8(color, 0, r)
	buffer.writeu8(color, 1, g)
	buffer.writeu8(color, 2, b)
	buffer.writeu8(color, 3, math.round(a * 255))
	return color
end

function color4.read_color3(color: color4)
	return Color3.new(
		buffer.readu8(color, 0) / 255,
		buffer.readu8(color, 1) / 255,
		buffer.readu8(color, 2) / 255
	)
end

function color4.read_alpha(color: color4)
	return 1 - (buffer.readu8(color, 3) / 255)
end

function color4.read(color: color4)
	return color4.read_color3(color), color4.read_alpha(color)
end

function color4.is_color4(value: any)
	return
		typeof(value) == "buffer" and
		buffer.len(value) == 4
end

return color4