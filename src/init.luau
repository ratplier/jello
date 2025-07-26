--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local widgets = script.widgets
local internal = require(script.internal)

export type props = internal.props
export type source<T> = internal.source<T>

local function create_target()
	local player = Players.LocalPlayer
	local player_gui = player and player:FindFirstChildOfClass("PlayerGui")
	
	local root = Instance.new("ScreenGui")
	root.IgnoreGuiInset = false
	root.ResetOnSpawn = false
	root.DisplayOrder = 1000
	root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	root.Name = "jello-root"
	root.Parent = player_gui
	return root
end

local function error_handler(message: string)
	internal._paused = true
	warn(message)
	print(debug.traceback())
end

local jello = {
	update_frequency = -1,
	version = "0.1.0",
	_initialized = nil :: boolean?,
	_target = nil :: Instance?,

	row = require(widgets.format.row),
	seperator = require(widgets.format.seperator),
	group = require(widgets.format.group),
	indent = require(widgets.format.indent),
	header = require(widgets.format.header),
	
	window = require(widgets.window),
	text = require(widgets.text),
	checkbox = require(widgets.checkbox),
	button = require(widgets.button),
	radiobutton = require(widgets.radiobutton),
	textinput = require(widgets.textinput),
}

function jello.create(class_name: string)
	return function(props: props)
		local id = internal.gen_id(1, class_name)
		
		internal.define_object(id, class_name, props)
		return internal.render(id)
	end
end

function jello.open(target: Instance)
	internal.push_parent(target)
end

function jello.close()
	internal.pop_parent()
end

function jello.scope(fn: () -> ())
	internal.scope(fn)
end

function jello.connect(fn: () -> ()): () -> ()
	return internal.listen(fn)
end

function jello.source<T>(default: T?): source<T>
	local id = internal.gen_id(1, "source")
	return internal.source(default, id)
end

function jello.step()
	if internal._paused then
		internal.clear_instances()
		return
	end

	internal.profile("mount-listeners")
	
	for listener in internal._listeners do
		listener()
	end
	
	internal.endprofile()
	
	local parent_stack_length = internal._parent_stack_length
	internal.assert(parent_stack_length <= 0, "too few calls to jello.close")
	internal.assert(parent_stack_length >= 0, "too many calls to jello.close")

	internal._tick += 1
	
	internal.profile("cleanup")
	internal.cleanup_frame()
	internal.endprofile()
	
	internal.profile("reset")
	internal.reset_framedata()
	internal.endprofile()
end

type init_args = {
	parent: Instance?,
	no_loop: boolean?,
	no_config: boolean?,
	frequency: number?,
}

function jello.init(args: init_args?)
	if jello._initialized :: any then return jello end
	
	local parent = args and args.parent
	local no_init = args and args.no_loop
	local no_config = args and args.no_config
	local frequency = args and args.frequency
	
	local target = parent or create_target()
	internal.update_target(target)
	
	if no_init ~= true then	 
		local focused = true
		local accumulator = 0
		
		UserInputService.WindowFocusReleased:Connect(function() focused = false end)
		UserInputService.WindowFocused:Connect(function() focused = true end)
		
		RunService.Heartbeat:Connect(function(delta_time)
			if focused == false then return end
			
			while accumulator >= jello.update_frequency do
				internal.profile("step")
				
				xpcall(jello.step :: any, error_handler)
				accumulator -= jello.update_frequency
				
				internal.endprofile()
			end
		
			accumulator += delta_time
		end)
	end
	
	if no_config ~= true then
		local object_count = 0
		local last_update = -1
		internal.update_config(function(instance: Instance, props: props)
			if last_update ~= internal._tick then
				last_update = internal._tick
				object_count = 0
			end
			object_count += 1
			
			if instance:IsA("GuiObject") and props.LayoutOrder == nil then
				instance.LayoutOrder = object_count
			end
			
			local id = tostring(object_count)
			instance.Name = id
		end)
	end
	
	jello.update_frequency = if frequency then frequency else 1/60
	jello._target = target
	
	return jello
end

return jello