--!strict
type id = string

type object<P=props> = {
	class_name: string,
	properties: P,
}

type listeners = { [string]: { (Instance, ...any) -> ()}}
type actions = { [(Instance) -> ()]: true }
export type props = { [any]: any } & { any }
export type source<T> = (T) -> () & () -> (T)

local defaults = require("./defaults")

local instances: { [id]: Instance } = {}
local instance_to_id = {} :: { [Instance]: string }
local instance_metadata: { [Instance]: {
	connections: { [any]: RBXScriptConnection },
	listeners: listeners,
	actions: actions,
} } = {}

local enviroment: { [string]: any } = { root = {} }

local function throw(message: string?, level: number?)
	error(`[jello]: {message}`, (level or 0) + 1)
end

local function djb_hash(str: string)
	local hash: number = 5381
	for i = 1, #str do
		local char_code = string.byte(str, i)
		local hash_times_33 = bit32.lshift(hash, 5) + hash
		hash = hash_times_33 + char_code
	end
	return  tostring(bit32.band(hash, 0xFFFFFFFF))
end

local function assert(condition: any, message: string?, level: number?)
	if not condition then throw(message, (level or 1) + 1) end
end

local function read_property(instance: Instance, key: any): any?
	local success, result = pcall(function()
		return (instance :: any)[key]
	end)

	assert(success, `"{key}" is not a valid property of "{instance.ClassName}"`)
	return result
end

local function write_property(instance: Instance, key: any, value: any)
	local success, result = pcall(function()
		(instance :: any)[key] = value
		return nil
	end)

	assert(success, `failed to write_property "{key}" to "{instance.ClassName}": {result}`)
end

local function get_value<T>(t: T | source<T>): T
	if typeof(t) == "function" then return (t::source<T>)() end
	return t
end

local function get_trash(instance: Instance)
	if instance_metadata[instance] then return instance_metadata[instance] end

	local trash = {
		connections = {},
		listeners = {},
		actions = {},
	}
	instance_metadata[instance] = trash
	return trash
end

local function merge_listeners(target: listeners, source: listeners)
	for event in source do
		local from = source[event]
		local to = target[event]
		
		if to ~= nil then
			table.move(from, 1, #from, #to + 1, to)
		else
			target[event] = from
		end
	end
end

local function process_properties(instance: Instance, props: props): (props, listeners, actions)
	local result_props: props = {}
	local result_events: listeners = {}
	local result_actions: actions = {}

	for key: any, value: any in props do
		if typeof(key) == "string" then
			if typeof(read_property(instance, key)) == "RBXScriptSignal" then
				local listeners = result_events[key] or {}
				table.insert(listeners, value)
				result_events[key] = listeners
			else
				result_props[key] = get_value(value)
			end
		elseif typeof(value) == "table" then
			local nested_props, nested_events = process_properties(instance, value :: props)
			result_props[key] = nested_props
			merge_listeners(result_events, nested_events)
		elseif typeof(value) == "function" then
			result_actions[value] = true
		else
			result_props[key] = value
		end
	end

	return result_props, result_events, result_actions
end

local function get_property_changes(instance: Instance, a_props: props?, b_props: props): props?
	local changed_props = {}
    a_props = (a_props or {}) :: props
	
	for key in b_props do
		local a_value = a_props[key]
		local b_value = b_props[key]

		local is_function = (type(a_value) == "function" or type(b_value) == "function")
		if type(key) == "string" and is_function then continue end

		if type(a_value) == "table" and type(b_value) == "table" then
			local a, b = (a_value :: props), (b_value :: props)
			changed_props[key] = get_property_changes(instance, a, b)
		elseif a_value ~= b_value then
			changed_props[key] = b_value :: any
		end
	end

	return if next(changed_props) then changed_props else nil
end

local function construct_object(class_name: string)
	local object = Instance.new(class_name)
	defaults:default(object, write_property)
	get_trash(object)
	return object
end

local function destruct_object(id: id)
	local instance = instances[id]
	if instance :: Instance? == nil then return end
	
	instance:Destroy()

	local metadata = instance_metadata[instance]
	for _, connection in metadata.connections do
		connection:Disconnect()
	end
	
	for name, listeners in metadata.listeners do
		if name ~= "Destroying" then continue end
		for _, cn in listeners do task.spawn(cn, instance) end
	end
	
	instance_metadata[instance] = nil
	instance_to_id[instance] = nil
	instances[id] = nil
end

local function update_connections(instance: Instance, new_listeners: listeners)
	local trash = get_trash(instance)

	for event_name, connection in trash.connections do
		if new_listeners[event_name] ~= nil then continue end
		
		connection:Disconnect()
		trash.connections[event_name] = nil
	end
	
	for event_name in new_listeners do
		if trash.connections[event_name] ~= nil then continue end

		local event_signal = read_property(instance, event_name)
		if typeof(event_signal) ~= "RBXScriptSignal" then continue end

		trash.connections[event_name] = event_signal:Connect(function(...)
			local connections = trash.listeners[event_name]
			if connections == nil then return end
			
			for _, listener in connections do
				task.spawn(listener, instance, ...)
			end
		end)
	end

	trash.listeners = new_listeners
end

local internal = {
	_env = "root",
	_debug = false,
	_paused = false,

	_tick = 0,

	_instances = instances,
	_instance_to_id = instance_to_id,
	_used_ids = {} :: { [id]: number },
	_pushed_ids = {} :: { id },
	_vdom = {} :: { [id]: object },
	_last_vdom = {} :: { [id]: object },
	_instance_metadata = instance_metadata,

	_parent_stack = {} :: { Instance },
	_parent_stack_length = 0,
	_target = nil :: Instance?,

	_listeners = {} :: { [() -> ()]: true },
	_config = nil :: ((Instance, props) -> ())?,
	_profile_count = 0,

	assert = assert,
	throw = throw,
	read = get_value,
	read_property = read_property,
	write_property = write_property,
	
	verbose = false,
}

function internal.profile(name: string)
	if internal._debug == false then return end
	debug.profilebegin(`jello::{name}`)

	internal._profile_count += 1
end

function internal.endprofile()
	if internal._debug == false then return end
	if internal._profile_count < 1 then return end

	internal._profile_count -= 1
	debug.profileend()
end

function internal.log(message: string, warning: boolean?)
	if internal._debug == false then return end
	
	local method = if warning then warn else print
	method(`[jello]: {message}`)
end

function internal.gen_id(ignore_levels: number?, prefix: string?): string
	ignore_levels = 1 + ( ignore_levels or 0 )
	prefix = prefix or "rbx-id"

	local line_number = debug.info(ignore_levels, "l")

	assert(
		line_number ~= nil,
		`could not generate a stable id, call stack is not deep enough (requested level: {ignore_levels})`
	)

	local ID = ""

	while line_number ~= -1 and line_number ~= nil do
		ID = `{ID}:{line_number}`
		ignore_levels += 1
		line_number = debug.info(ignore_levels, "l")
	end

	if not internal.verbose then
		ID = djb_hash(ID)
	end
	
	local pushed_ids = table.concat(internal._pushed_ids, "-")
	local discriminator = internal._used_ids[ID] or 0
	discriminator += 1
	internal._used_ids[ID] = discriminator
	
	local footer =
		if #pushed_ids == 0 then `[{discriminator}]`
		else `[{discriminator}, {pushed_ids}]`

	if internal.verbose then
		return `{prefix}({ID}): {footer}`
	else
		return `jello("{ID}", {footer})`
	end
end

function internal.push_id(id: any)
	table.insert(internal._pushed_ids, id)
end

function internal.pop_id()
	table.remove(internal._pushed_ids)
end

function internal.setenv(id: string, env: { [any]: any })
	enviroment[id] = env
	internal._env = id
end

function internal.getenv(name: string?)
	name = name or internal._env
	return enviroment[name]
end

function internal.set(key: string, value: any)
	internal.getenv()[key] = value
end

function internal.get(key: string)
	return internal.getenv()[key]
end

function internal.source<T>(default: T?, idx: string?): source<T>
	local id = idx or internal.gen_id(1, "source")
	local value =
		if internal.get(id) ~= nil then internal.get(id)
		else default
	
	internal.set(id, value)
	return function(...: any): any
		if select("#", ...) ~= 0 then
			return internal.set(id, ...)
		end
		return internal.get(id)
	end
end

function internal.define_object(id: id, class_name: string, properties: props)
	internal._vdom[id] = {
		class_name = class_name,
		properties = properties,
	}

	local instance = instances[id]
	if instance :: Instance? == nil then
		instance = construct_object(class_name)
		instances[id] = instance
	end

	if internal._config then
		internal._config(instance, properties)
	end
	
	instance_to_id[instance] = id
end

function internal.apply(instance: Instance, properties: props)
	local trash = get_trash(instance)

	for property, value in properties do
		if type(property) == "string" then
			write_property(instance, property, get_value(value))
		elseif type(property) == "number" then
			if (type)(value) == "function" then
				trash.actions[value] = true
			elseif (type)(value) == "table" then
				internal.apply(instance, value)
			elseif typeof(value) == "Instance" then
				write_property(value, "Parent", instance)
			end
		end
	end
	
	return instance
end

function internal.render(id: id)
	internal.profile("render")

	local object = internal._vdom[id]
	local last_object = internal._last_vdom[id]
	local instance = instances[id]
	
	local props, listeners, actions = process_properties(instance, object.properties)
	update_connections(instance, listeners)

	local last_props = last_object and last_object.properties
	local changes = get_property_changes(instance, last_props, props)
	if changes then internal.apply(instance, changes) end

	for action in actions do
		action(instance)
	end
	
	object.properties = props

	internal.endprofile()
	return instance
end

function internal.cleanup_frame()
	for id, obj in internal._last_vdom do
		if internal._vdom[id] ~= nil then continue end
		destruct_object(id)
	end

	table.clear(internal._last_vdom)
end

function internal.reset_framedata()
	for id, object in internal._vdom do
		internal._last_vdom[id] = object
	end

	table.clear(internal._vdom)
	table.clear(internal._pushed_ids)
	table.clear(internal._used_ids)
end

function internal.listen(callback: () -> ())
	internal._listeners[callback] = true
	return function()
		internal._listeners[callback] = nil
	end
end

function internal.update_config(fn: (instance: Instance, props: props) -> ())
	internal._config = fn
end

function internal.clear_instances()
	for id in instances do
		destruct_object(id)
	end
end

function internal.push_parent(parent: Instance)
	internal._parent_stack_length += 1
	table.insert(internal._parent_stack, parent)
end

function internal.pop_parent(depth: number?)
	internal._parent_stack_length -= 1

	local index = #internal._parent_stack - (depth or 0)
	table.remove(internal._parent_stack, index)
end

function internal.update_target(target: Instance)
	internal._target = target
end

function internal.get_parent()
	return internal._parent_stack[internal._parent_stack_length] or internal._target
end

function internal.mount(object: Instance, target: (Instance | "root")?)
	if target == "root" then
		target = internal._target
	end
	
	target = target or internal.get_parent()
	write_property(object, "Parent", target)
end

function internal.scope(fn: () -> ())
	internal.assert(
		internal._parent_stack_length > 0,
		"attempt to create scope without a parent"
	)
	
	local success, result = pcall(fn::any)
	internal.pop_parent()
	
	if not success then internal.throw(result) end
end

function internal.create(class: string, id: string?)
	return function(props: props): Instance
		local id = id or internal.gen_id(2, "create")
		internal.define_object(id, class, props)
		return internal.render(id)
	end
end

return internal
