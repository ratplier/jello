--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	opened: source<boolean>,
	hovered: source<boolean>,
	clicked: source<boolean>,
}

local menu_manager = {
	active_menu = nil :: state?,
	menus = {} :: {[Instance]: state},
}

function menu_manager.register(object: TextButton, state: state)
	menu_manager.menus[object] = state
end

function menu_manager.unregister(object: TextButton)
	local menu = menu_manager.menus[object]
	menu_manager.menus[object] = nil

	menu.opened(false)
end

function menu_manager.set_active(object: TextButton?)
	if menu_manager.active_menu then
		local last_menu = menu_manager.active_menu
		last_menu.opened(false)
	end

	local menu = menu_manager.menus[object :: any]
	menu_manager.active_menu = menu

	if not menu then return end
	menu.opened(true)
end

function menu_manager.handle(object: TextButton, state: state, contents: Frame)
	local can_switch = 
		menu_manager.active_menu ~= nil and
		menu_manager.active_menu ~= menu_manager.menus[object]
	
	if state.hovered() and can_switch then
		menu_manager.set_active(object)
	end

	if state.clicked() then
		menu_manager.set_active(object)
	end

	if root.mouse_clicked("Button1") and menu_manager.active_menu then
		local in_content_area = ui.is_mouse_over(contents)
		local in_button_area = ui.is_mouse_over(object)

		if not in_content_area and not in_button_area then
			menu_manager.set_active(nil)
		end
	end
end

local function create_contents(object: TextButton, state: state)
	local visible = root.source(false)
	local contents = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,

        Visible = visible,
        Position = function()
			local pos = object.AbsolutePosition
			local size = object.AbsoluteSize

			local position = vector.create(pos.X, pos.Y + size.Y)
			return UDim2.fromOffset(position.x, position.y)
        end,

        paint.tooltip(),

        ui.padding(config.padding),
        ui.constrain(nil, nil, 250, nil),
		ui.list_layout("Vertical", 0),
    } :: Frame
	
	local base_children = root.source(#contents:GetChildren())
	visible( state.opened() and #contents:GetChildren() > base_children() )
	return contents
end

return ui.widget("menu", function(name: string?)
	name = root.default(name, "Menu")
    local clicked = root.event()

	local state: state = {
		hovered = root.source(false),
		opened = root.source(false),
		clicked = root.source(false),
	}

	local main = root.create("TextButton") {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),

		Text = name,

        paint.text(),
		paint.menu(state.opened, state.hovered),

        ui.padding(0, config.spacing),
		ui.hovered(state.hovered),
		ui.clicked("Button1", function()
			clicked.fire()
		end),

		root.created(function(self)
			menu_manager.register(self :: TextButton, state)
		end),

		root.destroyed(function(self)
			menu_manager.unregister(self :: TextButton)
		end)
	} :: TextButton

	local contents = create_contents(main, state)
	menu_manager.handle(main, state, contents)

	ui.mount(main)
	ui.mount(contents, "root")

	state.clicked(clicked.fired())
	return ui.start_scope(contents, state)
end)




