--!strict
local root = require("./rootkit")

local adornments = {
	adornment = nil :: WireframeHandleAdornment?,
	aot_adornment = nil :: WireframeHandleAdornment?,
}

local last_update = -1
local state_stack = {}

local default_state = {
	color = Color3.new(0.937255, 0.0392157, 1),
	transparency = 0,
	always_on_top = false,
	target = workspace.Terrain,
}

type partial<T> = root.partial<T>

export type vec3 = Vector3 | vector
export type vec2 = Vector2

type state = typeof(default_state)

local function get_state()
	return state_stack[#state_stack]
end

local function get_adornment(): WireframeHandleAdornment
	local state = get_state()
	local result = 
		if state.always_on_top then adornments.aot_adornment
		else adornments.adornment

	root.assert(result, "attempt to use gizmos without intitalization")
	return result :: WireframeHandleAdornment
end

local function reconcile(target, key, value)
	if target[key] == value then return end
	target[key] = value
end

local function reconcile_state(adornment: WireframeHandleAdornment)
	local state = get_state()

	reconcile(adornment, "Color3", state.color)
	reconcile(adornment, "Transparency", state.transparency)
	reconcile(adornment, "AlwaysOnTop", state.always_on_top)

	reconcile(adornment, "Parent", state.target)
	reconcile(adornment, "Adornee", state.target)
end

local function push_state(override: partial<state>)
	local state = table.clone( get_state() )

	for k, v in override :: any do
		if typeof(state[k]) ~= typeof(v) then continue end
		state[k] = v
	end

	table.insert(state_stack, state)
	reconcile_state( get_adornment() )
end

local function pop_state()
	root.assert(#state_stack > 1, "too many calls to pop_state")
	
	table.remove(state_stack)
	reconcile_state( get_adornment() )
end

local function update()
	if last_update == root.get_tick() then return end
	last_update = root.get_tick()
	
	local adornment = get_adornment()
	reconcile_state(adornment)
	
	adornment:Clear()
end

local function draw_line(origin: Vector3, target: Vector3)
	update()
	local adornment = get_adornment()
	adornment:AddLine(origin, target)
end

local function draw_path(points: { Vector3 }, loop: boolean?)
	update()
	local adornment = get_adornment()
	adornment:AddPath(points, loop or false)
end

local function draw_text(point: Vector3, text: string, size: number?)
	update()
	local adornment = get_adornment()
	adornment:AddText(point, text, size)
end

local function init()
	local adornment = Instance.new("WireframeHandleAdornment")
	local aot_adornment = Instance.new("WireframeHandleAdornment")
	
	adornment.AlwaysOnTop = false
	aot_adornment.AlwaysOnTop = true
	
	adornments = {
		adornment = adornment,
		aot_adornment = aot_adornment,
	}
	
	local state = table.clone(default_state)
	table.insert(state_stack, state)
	
	reconcile_state(adornment)
	reconcile_state(aot_adornment)
end

local function create<T>(name: string, constructor: (T) -> ())
	local gizmo_id = root.gen_id(1, `gizmo::{name}`)

	return function(arguments: T)
		push_state(arguments)
		
		root.push_id(gizmo_id)
		constructor(arguments)
		root.pop_id()
		
		pop_state()
	end
end

return {
	draw_line = draw_line,
	draw_path = draw_path,
	draw_text = draw_text,
	
	init = init,
	create = create,
	
	push_state = push_state,
	pop_state = pop_state,
}