--!strict
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local internal = require("../internal")
local color4 = require("./color4")

type source<T> = internal.source<T>
type value<T> = source<T> | T
type color4 = color4.color4

export type scope<T> = (scope: T) -> ()
export type state<T={}> = T
export type scoped_state<T={}> = state<T> & { with: (scope: scope<T>) -> () }

export type fillDirection = "Vertical" | "Horizontal"
export type mouseButton = "Button1" | "Button2" | "Button3"
export type flexMode = "Fill" | "Grow" | "Shrink"
export type widgetConstructor<T, A...> = (A...) -> state<T>

local kit = {
	drag_target = nil,
	window_amount = 0,
}

function kit.mouse_position()
	local pos = UserInputService:GetMouseLocation()
	return vector.create(pos.X, pos.Y)
end

function kit.inset()
	local inset = GuiService:GetGuiInset()
	return vector.create(inset.X, inset.Y)
end

function kit.is_mouse_over(object: GuiObject)
	local inset = GuiService:GetGuiInset()
	local position = kit.mouse_position()
	local player = Players.LocalPlayer :: Player
	local playergui = player:FindFirstChildOfClass("PlayerGui")
	
	if not playergui then return false end

	local px, py = position.x - inset.X, position.y - inset.Y
	local instances = playergui:GetGuiObjectsAtPosition(px, py)
	local clicked_object = instances[1]
	
	if object:IsAncestorOf(clicked_object) or object == clicked_object then
		return true
	else
		return false
	end
end

function kit.clicked(mouse_button: value<mouseButton>, callback: (self: GuiObject, x: number, y: number) -> ())
	mouse_button = internal.read(mouse_button) :: mouseButton
	
	local input_type = Enum.UserInputType:FromName(`Mouse{mouse_button}`) or Enum.UserInputType.MouseButton1
	return {
		InputEnded = function(self, input: InputObject)
			if input.UserInputType ~= input_type then return end
			if not kit.is_mouse_over(self) then return end
			callback(self, input.Position.X, input.Position.Y)
		end,
	}
end

function kit.apply_color(property: value<string>, color: value<color4>)
	local key = internal.read(property) :: string
	local value = internal.read(color) :: color4

	local colorIndex = `{key}Color3`
	local transparencyIndex = `{key}Transparency`

	return {
		[transparencyIndex] = color4.read_alpha(value),
		[colorIndex] = color4.read_color3(value) :: any,
	}
end

function kit.list_layout(direction: fillDirection, padding: number)
	local fill_direction = Enum.FillDirection:FromName(direction)
	local vertical_alignment
	local horiztonal_alignment

	if direction == "Vertical" then
		vertical_alignment = Enum.VerticalAlignment.Top
		horiztonal_alignment = Enum.HorizontalAlignment.Left
	elseif direction == "Horizontal" then
		vertical_alignment = Enum.VerticalAlignment.Center
		horiztonal_alignment = Enum.HorizontalAlignment.Left
	end

	return internal.create("UIListLayout") {
		FillDirection = fill_direction,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = vertical_alignment,
		HorizontalAlignment = horiztonal_alignment,
		Padding = UDim.new(0, padding),
	}
end

function kit.corner(radius: number)
	return internal.create("UICorner") {
		CornerRadius = UDim.new(0, radius),
	}
end

function kit.circle()
	return internal.create("UICorner") {
		CornerRadius = UDim.new(1, 0),
	}
end

function kit.flexitem(name: flexMode)
	return internal.create("UIFlexItem") {
		FlexMode = Enum.UIFlexMode:FromName(name)
	}
end

function kit.constrain(min_x: number?, min_y: number?, max_x: number?, max_y: number?)
	return internal.create("UISizeConstraint") {
		MinSize = Vector2.new(min_x or 0, min_y or 0),
		MaxSize = Vector2.new(max_x or math.huge, max_y or math.huge),
	}
end

function kit.aspect_ratio(x: number, y: number?)
	return internal.create("UIAspectRatioConstraint") {
		AspectRatio = x / (y or 1),
		DominantAxis = Enum.DominantAxis.Height
	}
end

function kit.hovered(fn: (boolean) -> ())
	return function(self)
		local hovered = kit.is_mouse_over(self)
		fn(hovered)
	end
end

kit.padding = function(...)
	local t,b,l,r
	local args = { ... }

	if #args == 1 then
		t, b, l, r = args[1], args[1], args[1], args[1]
	elseif #args == 2 then
		t, b, l, r = args[1], args[1], args[2], args[2]
	elseif #args == 4 then
		t, b, l, r = args[1], args[2], args[3], args[4]
	else
		internal.throw("Invalid number of arguments", 0)
	end

	return internal.create("UIPadding") {
		PaddingTop = UDim.new(0, t),
		PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r),
	}
end :: 
& ((offset: number) -> UIPadding)
& ((vertical: number, horizontal: number) -> UIPadding)
& ((top: number, bottom: number, left: number, right: number) -> UIPadding)

function kit.widget<C, T, A...>(name: string, constructor: widgetConstructor<T, A...> & C): C
	local widget_id = internal.gen_id(1, `widget::{name}`)

	return function(...: A...)
		internal.push_id(widget_id)
		local object: any = constructor(...)
		internal.pop_id()
		return object
	end :: any
end

function kit.start_scope<T>(target: Instance, state: (T & any)?): scoped_state<T>
	state = if type(state) == "table" then state else {} :: T
	(state::any).with = function(fn)
		return internal.scope(function() fn(state) end)
	end
	internal.push_parent(target)
	return state
end

return kit