export type aabb = { min: vector, max: vector }

local function create(min: vector, max: vector): aabb
	return { min = min, max = max }
end

local function from_components(
	min_x: number,
	min_y: number,
	max_x: number,
	max_y: number
): aabb
	return create(
		vector.create(min_x, min_y),
		vector.create(max_x, max_y)
	)
end

local function zero(): aabb
	return from_components(0, 0, 0, 0)
end

local function one(): aabb
	return from_components(1, 1, 1, 1)
end

local function is_aabb(unknown: unknown): boolean
	return
		type(unknown) == "table" and
		type((unknown :: any).min) == "vector" and
		type((unknown :: any).max) == "vector"
end

return {
    create = create,
	from_components = from_components,

    zero = zero,
    one = one,

	is_aabb = is_aabb,
}