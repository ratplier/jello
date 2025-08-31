--!strict
local UserInputService = game:GetService("UserInputService")

local root = require("./rootkit")
local paint = require("./paint")
local ui = require("./uikit")
local config = require("../config")

local row = require("../widgets/format/row")

type source<T> = root.source<T>
type value<T> = root.value<T>

export type DataType = "number" | "Vector2" | "Vector3" | "vector" | "UDim" | "UDim2" | "Color3" | "buffer" | "Rect" | string
export type options = {
	prefix: string?,
	align: ("Left" | "Center" | "Right" | string)?,

	id_suffix: string?,

	min: number?,
	max: number?,
	increment: number?,
	decimal_places: number?,

	has_buttons: boolean?,
	has_color_preview: boolean?,
}

type component_options = {
	width: UDim,
	value_source: source<number>,
	on_change: (new_value: number) -> (),
}

type increment_options = {
	value_source: source<number>,
	increment_by: number,
	on_change: ((incremented: boolean) -> ())?,
}

local DATA_TYPES = { "number", "Vector2", "Vector3", "vector", "UDim", "UDim2", "Color3", "buffer", "Rect" }
local DATA_TYPE_SIZES = { number = 1, Vector2 = 2, Vector3 = 3, vector = 3, UDim = 2, UDim2 = 4, Color3 = 3, buffer = 4, Rect = 4 }
local DRAG_PRECISION = 12

local BUTTON_SIZE = config.rowHeight + config.padding

local read_handlers: { [DataType]: (any, number) -> any } = {
	number = function(value: number, index: number): number
		return value
	end,
	Vector2 = function(value: Vector2, index: number): number
		if index == 1 then return value.X end
		if index == 2 then return value.Y end
		error("Index out of range")
	end,
	Vector3 = function(value: Vector3, index: number): number
		if index == 1 then return value.X end
		if index == 2 then return value.Y end
		if index == 3 then return value.Z end
		error("Index out of range")
	end,
	vector = function(value: vector, index: number): number
		if index == 1 then return value.x end
		if index == 2 then return value.y end
		if index == 3 then return value.z end
		error("Index out of range")
	end,
	UDim = function(value: UDim, index: number): number
		if index == 1 then return value.Scale end
		if index == 2 then return value.Offset end
		error("Index out of range")
	end,
	UDim2 = function(value: UDim2, index: number): number
		if index == 1 then return value.X.Scale end
		if index == 2 then return value.X.Offset end
		if index == 3 then return value.Y.Scale end
		if index == 4 then return value.Y.Offset end
		error("Index out of range")
	end,
	Rect = function(value: Rect, index: number): number
		if index == 1 then return value.Min.X end
		if index == 2 then return value.Min.Y end
		if index == 3 then return value.Max.X end
		if index == 4 then return value.Max.Y end
		error("Index out of range")
	end,
	Color3 = function(value: Color3, index: number): number
		if index == 1 then return value.R * 255 end
		if index == 2 then return value.G * 255 end
		if index == 3 then return value.B * 255 end
		error("Index out of range")
	end,
	Color3_HSV = function(value: Color3, index: number): number
		local h, s, v = value:ToHSV()
		if index == 1 then return h * 255 end
		if index == 2 then return s * 255 end
		if index == 3 then return v * 255 end
		error("Index out of range")
	end,
	buffer = function(value: buffer, index: number): number
		return buffer.readu8(value, index - 1)
	end,
}

local write_handlers: { [DataType]: (any, number, any) -> any } = {
	number = function(target: number, index: number, value: number): number
		return value
	end,
	Vector2 = function(target: Vector2, index: number, value: number): Vector2
		if index == 1 then return Vector2.new(value, target.Y) end
		if index == 2 then return Vector2.new(target.X, value) end
		error("Index out of range")
	end,
	Vector3 = function(target: Vector3, index: number, value: number): Vector3
		if index == 1 then return Vector3.new(value, target.Y, target.Z) end
		if index == 2 then return Vector3.new(target.X, value, target.Z) end
		if index == 3 then return Vector3.new(target.X, target.Y, value) end
		error("Index out of range")
	end,
	vector = function(target: vector, index: number, value: number): { x: number, y: number, z: number }
		if index == 1 then return vector.create(value, target.y, target.z) end
		if index == 2 then return vector.create(target.x, value, target.z) end
		if index == 3 then return vector.create(target.x, target.y, value) end
		error("Index out of range")
	end,
	UDim = function(target: UDim, index: number, value: number): UDim
		if index == 1 then return UDim.new(value, target.Offset) end
		if index == 2 then return UDim.new(target.Scale, value) end
		error("Index out of range")
	end,
	UDim2 = function(target: UDim2, index: number, value: number): UDim2
		if index == 1 then return UDim2.new(value, target.X.Offset, target.Y.Scale, target.Y.Offset) end
		if index == 2 then return UDim2.new(target.X.Scale, value, target.Y.Scale, target.Y.Offset) end
		if index == 3 then return UDim2.new(target.X.Scale, target.X.Offset, value, target.Y.Offset) end
		if index == 4 then return UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, value) end
		error("Index out of range")
	end,
	Rect = function(target: Rect, index: number, value: number): Rect
		if index == 1 then return Rect.new(value, target.Min.Y, target.Max.X, target.Max.Y) end
		if index == 2 then return Rect.new(target.Min.X, value, target.Max.X, target.Max.Y) end
		if index == 3 then return Rect.new(target.Min.X, target.Min.Y, value, target.Max.Y) end
		if index == 4 then return Rect.new(target.Min.X, target.Min.Y, target.Max.X, value) end
		error("Index out of range")
	end,
	Color3 = function(target: Color3, index: number, value: number): Color3
		if index == 1 then return Color3.fromRGB(value, target.G * 255, target.B * 255) end
		if index == 2 then return Color3.fromRGB(target.R * 255, value, target.B * 255) end
		if index == 3 then return Color3.fromRGB(target.R * 255, target.G * 255, value) end
		error("Index out of range")
	end,
	Color3_HSV = function(target: Color3, index: number, value: number): Color3
		local h, s, v = target:ToHSV()
		if index == 1 then return Color3.fromHSV(value / 255, s, v) end
		if index == 2 then return Color3.fromHSV(h, value / 255, v) end
		if index == 3 then return Color3.fromHSV(h, s, value / 255) end
		error("Index out of range")
	end,
	buffer = function(target: buffer, index: number, value: number): buffer
		buffer.writeu8(target, index - 1, value)
		return target
	end,
}

local DEFAULTS = {
	prefixes = {
		number = { "" },
		Vector2 = { "x: ", "y: " },
		Vector3 = { "x: ", "y: ", "z: " },
		UDim = { "", "" },
		UDim2 = { "", "", "", "" },
		Color3 = { "r: ", "g: ", "b: " },
		Color3_HSV = { "h: ", "s: ", "v: " },
		Rect = { "", "", "", "" },
	},
	decimal_places = {
		number = { 0 },
		Vector2 = { 0, 0 },
		Vector3 = { 0, 0, 0 },
		UDim = { 2, 0 },
		UDim2 = { 2, 0, 2, 0 },
		Color3 = { 0, 0, 0 },
		Color3_HSV = { 0, 0, 0 },
		Rect = { 0, 0, 0, 0 },
	},
}

local function is_valid_data_type(value: any)
	return table.find(DATA_TYPES, typeof(value)) ~= nil
end

local function read_component_value<T>(target: T, index: number, suffix: string?): number
	root.assert(is_valid_data_type(target), "invalid data type for reading component value")

	local handler_id = (typeof(target) :: DataType) .. (suffix or "")
	local handler = read_handlers[handler_id]

	if handler then
		return handler(target, index)
	end

	error(`unknown data type or index for read: {handler_id}, {index}`)
end

local function write_component_value<T>(target: T, index: number, value: any, suffix: string?): T
	root.assert(is_valid_data_type(target), "invalid data type for writing component value")

	local handler_id = (typeof(target) :: DataType) .. (suffix or "")
	local handler = write_handlers[handler_id]

	if handler then
		return handler(target, index, value)
	end

	error(`unknown data type or index for write: {handler_id}, {index}`)
end

local function get_component_count(value: any): number
	root.assert(is_valid_data_type(value), "invalid data type for getting component count")
	return DATA_TYPE_SIZES[typeof(value) :: DataType]
end

local function get_default(category: string, item: string?)
	local result = DEFAULTS[category]
	if result and item then
		result = (result :: any)[item]
	end
	return result
end

local function truncate_number(value: number, decimal_places: number)
	local multiplier = 10 ^ decimal_places
	return math.floor(value * multiplier) / multiplier
end

local function apply_modifiers(value: number, options: options)
	return math.clamp(value, options.min or -math.huge, options.max or math.huge)
end

local function create_input_component(params: component_options, options: options?)
	local resolved_options = options or {} :: options
	local decimal_places = resolved_options.decimal_places
	local text_align = Enum.TextXAlignment:FromName(resolved_options.align or "Left")
	local prefix = resolved_options.prefix or ""

	local value_source = params.value_source
	local on_change = params.on_change

	local function format_text()
		local formatted_value = value_source()
		formatted_value = string.format(`%.{decimal_places}f` :: any, formatted_value)
		return `{prefix}{formatted_value}`
	end

	local is_active = root.source(false)
	local drag_connection: RBXScriptConnection?
	local ended_connection: RBXScriptConnection?

	local textbox = root.create("TextBox") {
		function(self: TextBox)
			is_active(not root.keys_pressed("LeftControl", "RightControl"))
		end,

		AutomaticSize = Enum.AutomaticSize.Y,
		ClearTextOnFocus = false,
		TextXAlignment = text_align,
		TextTruncate = Enum.TextTruncate.None,

		ClipsDescendants = true,

		Active = is_active,
		Text = format_text,
		Size = UDim2.new(params.width, UDim.new(0, 0)),

		paint.text(),
		paint.background(),
		ui.padding(config.padding),

		Focused = function(self: TextBox)
			self.CursorPosition = #self.Text + 1
			self.SelectionStart = #prefix + 1
		end,

		FocusLost = function(self: TextBox)
			local text_to_parse = self.Text
			if prefix ~= "" and text_to_parse:sub(1, #prefix) == prefix then
				text_to_parse = text_to_parse:sub(#prefix + 1)
			end

			local new_value = tonumber(text_to_parse)
			local precision = decimal_places or DRAG_PRECISION

			if
				new_value and
				truncate_number(new_value, precision) == new_value and
				apply_modifiers(new_value, resolved_options) == new_value
			then
				on_change(apply_modifiers(new_value, resolved_options))
			end
		end,

		InputBegan = function(self: TextBox, input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if drag_connection then return end
			if is_active() then return end

			self:ReleaseFocus()

			local start_mouse_position = input.Position
			local start_value = value_source()
			drag_connection = UserInputService.InputChanged:Connect(function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

				local delta_x = start_mouse_position.X - input.Position.X
				local precision = decimal_places or DRAG_PRECISION
				local new_value = truncate_number(start_value + delta_x / config.drag_sensitivity, precision)
				on_change(apply_modifiers(new_value, resolved_options))
			end)

			ended_connection = UserInputService.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if drag_connection ~= nil then
                    drag_connection:Disconnect()
                    drag_connection = nil
				end

                if ended_connection ~= nil then
                    ended_connection:Disconnect()
                    ended_connection = nil
                end
			end)
		end,
	}

	if textbox:IsA("TextBox") and not textbox:IsFocused() then
		textbox.Text = format_text()
	end

	return {
		object = textbox,
	}
end

local function create_button(text: string, on_click: (self: GuiObject, x: number, y: number) -> ())
	local clicked = root.event()
	local hovered = root.source(false)

	return root.create("TextLabel") {
		Active = true,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),

		paint.text(),
		paint.button(clicked.fired, hovered),

		ui.hovered(hovered),
		ui.clicked("Button1", function(self, x, y)
			clicked.fire()
			on_click(self, x, y)
		end),
	}
end

local function create_increment(params: increment_options)
	assert(params.increment_by > 0, "increment must be greater than 0")
	assert(is_valid_data_type(params.value_source()), "invalid datatype passed to create_increment")

	local function on_button_click(is_add: boolean)
		local current_value = params.value_source()
		local increment = params.increment_by * (if is_add then 1 else -1)
		local new_value = truncate_number(current_value + increment, DRAG_PRECISION)

		params.value_source(new_value)
		if params.on_change then params.on_change(is_add) end
	end

	local add_button = create_button("+", function() on_button_click(true) end)
	local subtract_button = create_button("-", function() on_button_click(false) end)

	ui.mount(function()
        return root.create("Frame") {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,

            add_button,
            subtract_button,

            ui.list_layout("Horizontal", config.spacing),
        }
    end)
end

local function create_color_preview(color_source: value<Color3>, transparency_source: value<number>?)
	local object = root.create("Frame") {
		Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
		BackgroundColor3 = root.read(color_source),
		BackgroundTransparency = root.read(transparency_source or 0),
	}

	ui.mount(object)
	return object
end

local function get_value_at_index(collection: any, index: number)
	if typeof(collection) == "table" then
		return (collection :: any)[index]
	end
	return collection
end

local function get_buttons_width(has_increment_buttons: boolean?, has_color_preview: boolean?)
	local button_count = 0
	if has_increment_buttons then button_count += 2 end
	if has_color_preview then button_count += 1 end
	return (BUTTON_SIZE + config.spacing) * button_count
end

local function create_data_type_inputs(value: root.value<any>, options: options?)
	local raw_value = root.read(value)
	local data_type = typeof(raw_value)
	local resolved_options = root.default(options, {}) :: options
	local suffix = resolved_options.id_suffix or ""
	local data_type_id = data_type .. suffix

	local tracked_suffix = root.from(suffix)
	local suffix_changed = tracked_suffix() ~= suffix
	if suffix_changed then
		tracked_suffix(suffix)
	end

	local prefixes = resolved_options.prefix or get_default("prefixes", data_type_id)
	local min = resolved_options.min
	local max = resolved_options.max
	local increment = resolved_options.increment
	local decimal_places = resolved_options.decimal_places or get_default("decimal_places", data_type_id)

	local component_count = get_component_count(raw_value)
	local buttons_width = get_buttons_width(resolved_options.has_buttons, resolved_options.has_color_preview)
	local component_width = UDim.new(
		config.input_width / component_count,
		-(config.spacing + (buttons_width / component_count))
	)

	local components = {}
	local target_source = root.from(value)
	local changed = root.event()

	for i = 1, component_count do
		local component_value = root.from(read_component_value(raw_value, i, suffix))

		if root.source_changed(target_source) or suffix_changed then
			local updated_component_value = read_component_value(root.read(target_source), i, suffix)
			component_value(updated_component_value)
		end

		local function on_component_change(new_value: number)
			local new_target_value = write_component_value(root.read(target_source), i, new_value, suffix)
			target_source(new_target_value)
			changed.fire()
		end

		local component_options: options = {
			align = resolved_options.align or "Left",
			min = min,
			max = max,
			prefix = get_value_at_index(prefixes, i),
			decimal_places = get_value_at_index(decimal_places, i),
		}

		local component_params: component_options = {
			width = component_width,
			value_source = component_value,
			on_change = on_component_change,
		}

		local component = create_input_component(component_params, component_options)
		ui.mount(component.object)

		table.insert(components, {
			object = component.object,
			value = component_value,
		})
	end

	if resolved_options.has_buttons and increment and #components > 0 then
		local first_component_source = components[1].value
		local increment_params: increment_options = {
			value_source = first_component_source,
			increment_by = increment,
			on_change = function()
				local new_parent_value = write_component_value(
					root.read(target_source), 1,
					first_component_source(), suffix
				)
				target_source(new_parent_value)
				changed.fire()
			end,
		}

		create_increment(increment_params)
	end

	if resolved_options.has_color_preview and data_type == "Color3" then
		create_color_preview(target_source :: source<Color3>)
	end

	return {
		changed = root.derive(changed.fired),
		value = target_source,
	}
end

local function create_input_label(text: string)
	ui.mount(function()
		return root.create("TextLabel") {
			Text = text,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(1, 0),

			paint.text(),
			paint.no_background(),

			ui.flexitem("Shrink"),
		}
	end)
end

local function get_decimal_places(n: number)
	local s = tostring(n)
	local i = s:find("%.")
	return if i then s:len() - i else 0
end

return {
	DEFAULTS = DEFAULTS,
	row = row,

	is_valid_data_type = is_valid_data_type,
	get_decimal_places = get_decimal_places,
	get_component_count = get_component_count,
	read_component_value = read_component_value,
	write_component_value = write_component_value,
	get_default = get_default,

	create_input_label = create_input_label,
	create_input_component = create_input_component,
	create_increment = create_increment,
	create_color_preview = create_color_preview,
	create_data_type_inputs = create_data_type_inputs,
}