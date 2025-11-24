export type rect = { min: vector, max: vector }
type rect_ctor =
	& ( (min: vector, max: vector) -> rect )
	& ( (minX: number, minY: number, maxX: number, maxY: number) -> rect )
	& ( ({ min: vector, max: vector }) -> rect )
	& ( ({ number }) -> rect )

local function rect(a: any, b: any, c: any, d: any): rect
	if type(a) == "table" then
		if type(a.min) == "vector" and type(a.max) == "vector" then
			return a
		end

		local tmp: any = a
		a, b, c, d = tmp[1], tmp[2], tmp[3], tmp[4]
	end
	
	local minv, maxv = a, b
	if type(minv) ~= "vector" or type(maxv) ~= "vector" then
		assert(
			type(a) == "number" and
			type(b) == "number" and
			type(c) == "number" and
			type(d) == "number",
		
			"Invalid arguments to rect"
		)
		
		minv, maxv = vector.create(a, b), vector.create(c, d)
	end
	return { min = minv, max = maxv }
end

local function from_center_size(position: vector, size: vector)
	local half_size = size * 0.5
	return {
		min = position - half_size,
		max = position + half_size,
	}
end

local function zero(): rect
	return rect(0, 0, 0, 0)
end

local function one(): rect
	return rect(1, 1, 1, 1)
end

local function is_rect(unknown: unknown): boolean
	return
		type(unknown) == "table" and
		type((unknown :: any).min) == "vector" and
		type((unknown :: any).max) == "vector"
end

return {
    create = rect :: rect_ctor,
    from_center_size = from_center_size,

    zero = zero,
    one = one,

	is_rect = is_rect,
}