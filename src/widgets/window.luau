--!strict
local UserInputService = game:GetService("UserInputService")

local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")
local extern_menubar = require("./menu/menubar")

local START_POSITION = vector.create(200, 200)
local DEFAULT_SIZE = vector.create(400, 400)
local OFFSET_INCREMENT = vector.create(30, 30)

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

type state = {
	active: source<boolean>,
	collasped: source<boolean>,
	closed: source<boolean>,
	
	position: source<vector>,
	size: source<vector>,
	zindex: source<number>,

	menubar: () -> ui.scoped_state,
}
export type arguments = {
	title: string,
	
	closeable: boolean?,
	noMinimize: boolean?,
	noTitle: boolean?,
	noTopbar: boolean?,
	noResize: boolean?,
	noDrag: boolean?,
}

local wm = {
	drag_connection = nil,
	window_stack = {},
	last_update = -1,
	last_tick = -1,
}

function wm.register(applier: (x: number, y: number) -> (), ignore_zindex: boolean?)
	local input_type = Enum.UserInputType.MouseButton1
	
	return {
		InputBegan = function(object: GuiObject, input: InputObject)
			if input.UserInputType ~= input_type then return end
			if wm.drag_connection ~= nil then return end

			if ignore_zindex ~= true then wm.push_to_top(object) end

			local last_position = input.Position
			wm.drag_connection = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

				local delta = last_position - input.Position
				last_position = input.Position
				applier(delta.X, delta.Y)
			end)
		end,

		InputEnded = function(_, input: InputObject)
			if input.UserInputType ~= input_type then return end
			if wm.drag_connection == nil then return end

			wm.drag_connection:Disconnect()
			wm.drag_connection = nil
		end,
		
		Destroying = function(object: GuiObject)
			if wm.drag_connection and wm.drag_connection.Connected then
				wm.drag_connection:Disconnect()
			end
			
			wm.unregister(object)
		end,
	}
end

function wm.get_next_position()
	local start_instance = wm.window_stack[#wm.window_stack] :: any
	local start_pos = start_instance and start_instance.Parent.AbsolutePosition :: Vector2
	
	if start_pos == nil then
		return START_POSITION
	else
		return vector.create(start_pos.X, start_pos.Y) + OFFSET_INCREMENT
	end
end

function wm.unregister(object: GuiObject)
	for index, obj in wm.window_stack do
		if obj ~= object then continue end
		table.remove(wm.window_stack, index :: any)
		break
	end
end

function wm.get_index(object: GuiObject)
	for index, obj in wm.window_stack do
		if obj ~= object then continue end
		return index
	end
	return -1
end

function wm.push_to_top(object: GuiObject)
	wm.unregister(object)
	table.insert(wm.window_stack, object)
	
	if wm.updated() then return end
	wm.last_update = root.get_tick()
end

function wm.get_active()
	return wm.window_stack[#wm.window_stack]
end

function wm.updated()
	return wm.last_update == root.get_tick()
end

local function topbar(state: state, args: arguments)
	local title_button_size = config.textSize - 1.5
	
	return root.create("Frame") {
		function(object) state.zindex( wm.get_index(object) ) end,
		
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 0),
		
		wm.register(function(x, y)
			local last_position = state.position()
			local target_position = last_position - vector.create(x, y)
			state.position(target_position)
		end),

		ui.padding(config.spacing / 2, config.spacing),
		ui.list_layout("Horizontal", config.spacing),
		paint.title(state.active, state.collasped),
		
		root.conditional(not args.noMinimize, function()
			return root.create("ImageLabel") {
				Active = true,
		
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(title_button_size, title_button_size),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				

				Image = function()
					return
						if state.collasped() then assets.rightPointingTriangle
						else assets.downPointingTriangle
				end,
				
				paint.image(),
				ui.clicked("Button1", function()
					state.collasped(not state.collasped())
				end),
			}
		end),

		root.conditional(not args.noTitle, function()
			return root.create("TextLabel") {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, title_button_size),
				LayoutOrder = 2,
				Interactable = false,
				
				Text = root.default(args.title, "Window"),
				TextSize = config.textSize,
				Font = config.font,
				
				ui.flexitem("Fill"),
				paint.text(state.active),
			}
		end),

		root.conditional(args.closeable, function()
			return root.create("ImageLabel") {
				Active = true,
				
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(title_button_size, title_button_size),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundTransparency = 1,
				LayoutOrder = 3,

				Image = assets.xCloseIcon,

				paint.image(),
				--TODO: implement closing listeners
			}
		end),
	}
end

local function resize_grip(state: state, args: arguments)
	return root.create("ImageLabel") {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(25, 25),
		
		BackgroundTransparency = 1,
		Rotation = 90,
		Image = assets.bottomRightCorner,
		
		Visible = not state.collasped(),
		ZIndex = 2,
		
		paint.resize_grip(),
		wm.register(function(x, y)
			local last_size = state.size()
			local target_size = last_size - vector.create(x, y)

			local new_x = math.max(config.minWindowSize.x, target_size.x)
			local new_y = math.max(config.minWindowSize.y, target_size.y)

			state.size(vector.create(new_x, new_y))
		end, true),
	}
end

local function user_contents(state: state, args: arguments)
	return root.create("ScrollingFrame") {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,

		LayoutOrder = 2,
		Visible = not state.collasped(),
		
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 0,
		
		ui.padding(10),
		ui.flexitem("Shrink"),
		ui.list_layout("Vertical", config.spacing)
	}
end

local function menubar(state: state, args: arguments)
	return root.create("Frame") {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),

		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}
end

local function contents(state: state, args: arguments)
	local menubar = menubar(state, args)
	local user_contents = user_contents(state, args)
	local contents = root.create("Frame") {
		Position = UDim2.new(0, 0, 0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		BackgroundTransparency = 1,
		
		LayoutOrder = 1,
		Visible = not state.collasped(),
		ui.list_layout("Vertical", 0),

		menubar,
		user_contents,
	}

	return {
		contents = contents,
		menubar = menubar,
		user_contents = user_contents,
	}
end

return ui.widget("window", function(arguments: partial<arguments>?)
	local args = root.default(arguments, { noClose = true }) :: arguments
	local state = {
		closed = root.source(false),
		collasped = root.source(false),
		active = root.source(true),
		
		position = root.source(START_POSITION),
		size = root.source(DEFAULT_SIZE),
		zindex = root.source(-1),
	} :: state
	
	local contents = contents(state, args)
	local topbar = root.conditional(not args.noTopbar, topbar, state, args)::any
	(state::any).menubar = function()
		local menubar = contents.menubar
		root.open_scope(menubar)
		local extern = extern_menubar()
		root.close_scope(1)
		return extern
	end

	local main = root.create("Frame") {
		ClipsDescendants = true,
		ZIndex = state.zindex(),

		Size = function()
			local size = state.size()
			local collapsed = state.collasped()

			return if collapsed
				then UDim2.fromOffset(size.x, 28)
				else UDim2.fromOffset(size.x, size.y)
		end,

		Position = function()
			local pos = state.position()
			return UDim2.fromOffset(pos.x, pos.y)
		end,

		contents.contents,
		topbar,
		
		root.conditional(not args.noResize, resize_grip, state, args),
		paint.window(state.collasped),
		
		ui.clicked("Button1", function()
			wm.push_to_top(topbar)
		end),
		
		root.created(function()
			state.position(wm.get_next_position())
			wm.push_to_top(topbar)
		end),
		
		root.destroyed(function()
			wm.unregister(topbar)
		end)
	}
	
	if wm.get_active() == topbar then
		state.active(true)
	else
		state.active(false)
	end

	ui.mount(main)
	return ui.start_scope(contents.user_contents, state)
end)
