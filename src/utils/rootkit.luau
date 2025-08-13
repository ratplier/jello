--!strict
local UserInputService = game:GetService("UserInputService")

local internal = require("../internal")

export type source<T> = internal.source<T>
export type value<T> = T | source<T>
export type props = internal.props

type function _partial(object: type)
	local tag = object.tag

	if tag == "union" or tag == "intersection" then
		local result

		for _, component in object:components() do
			if component.tag == "nil" then continue end
			if result == nil then
				result = component
				continue
			end

			result = types.unionof(result, component)
		end

		return types.optional(result :: type)
	elseif tag == "table" then
		local result = types.newtable()

		for key, prop in object:properties() do
			if prop.read ~= prop.write then continue end
			result:setproperty(key, _partial(prop.read))
		end

		return result
	end

	return types.optional(object)
end
export type partial<T> = _partial<T>

local kit = {
	gen_id = internal.gen_id,
	throw = internal.throw,
	assert = internal.assert,
	read = internal.read,
}

function kit.get_tick()
	return internal._tick
end

function kit.create(class_name: string)
	return function(props: internal.props)
		local id = internal.gen_id(2, "create")
		return internal.create(class_name, id)(props)
	end
end

function kit.gen_id(ignore_levels: number?, prefix: string?)
	ignore_levels = (ignore_levels or 0) + 1
	return internal.gen_id(ignore_levels, prefix)
end

function kit.source<T>(default: T?): source<T>
	local id = internal.gen_id(1, "create")
	return internal.source(default, id)
end

function kit.from<T>(value: value<T>): source<T>
	if typeof(value) == "function" then
		return value
	end
	return kit.source(value)
end

function kit.source_changed<T>(value: source<T>): boolean
	local val: () -> any = value
	local last_value = kit.source( val() )
	if last_value() ~= val() then 
		last_value(val())
		return true
	end
	return false
end

kit.derive = function<T>(fn)
	local src = internal.source()
	local value = internal.read(fn) :: T & any
	if value ~= src() then src(value) end
	return src
end ::
	& (<T>(fn: () -> T) -> source<T>)
	& (<T>(value: T) -> source<T>)

function kit.default<T>(value: any?, default: T): T
	local ref_type = typeof(default)
	local value_type = typeof(value)

	if value_type ~= ref_type then return default end
	if ref_type ~= "table" and value_type ~= "table" then
		return if value ~= nil then value else default
	elseif value_type ~= "table" then return default end

	local result = value :: any
	for key, value in default :: any do
		if result[key] ~= nil then continue end
		result[key] = value
	end
	return result
end

function kit.once<A...>(fn: (A...) -> (), ...: A...)
	local started = internal.source(false)
	if started() == false then
		fn(...)
		started(true)
	end
end

function kit.changed<T>(property: string, fn: (self: Instance, T) -> ())
	return {
		Changed = function(self: Instance, prop: string)
			if prop ~= property then return end
			fn( self, internal.read(property) )
		end,
	}
end

function kit.open_scope(target: Instance)
	internal.push_parent(target)
end

function kit.close_scope(depth: number?)
	internal.pop_parent(depth)
end

function kit.conditional<T, R, A...>(callback: value<T> | T, fn: (A...) -> R, ...: A...): R
	if internal.read(callback) ~= true then return nil end
	return fn(...)
end

function kit.mount(object: Instance | () -> Instance, target: (Instance | "root")?)
	if typeof(object) == "function" then
		internal.mount(object(), target)
	else
		internal.mount(object, target)
	end
end

function kit.created(fn: () -> ())
	return function(inst)
		local id = internal._instance_to_id[inst]
		local run = internal._vdom[id] ~= nil and internal._last_vdom[id] == nil
		if run then fn() end
	end
end

function kit.destroyed(fn: () -> ())
	return { Destroying = fn, } :: any
end

function kit.apply(instance: Instance, properties: internal.props)
	return internal.apply(instance, properties)
end

function kit.event(): { fire: () -> (), fired: () -> boolean }
	local last_updated = internal.source(-1)
	return {
		fire = function()
			last_updated(internal._tick)
		end,
		fired = function()
			return last_updated() == internal._tick
		end
	}
end

function kit.keys_pressed(...: Enum.KeyCode | string): boolean
	for _, key: Enum.KeyCode in { ... } do
		if key == "any" then return true end
		if key == "none" then return false end

		if typeof(key) == "string" then
			key = Enum.KeyCode:FromName(key) :: Enum.KeyCode
		end
		if key == Enum.KeyCode.Unknown then continue end

		if UserInputService:IsKeyDown(key :: Enum.KeyCode) then
			return true
		end
	end
	return false
end

function kit.force(property: string, value: any)
	return function(self: Instance)
		internal.write_property(self, property, internal.read(value))
	end
end

return kit