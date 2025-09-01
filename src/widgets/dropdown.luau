--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local row = require("./format/row")
local text = require("./text")
local assets = config.assets

type source<T> = root.source<T>
type value<T> = root.value<T>
type partial<T> = root.partial<T>

export type state = {
	opened: source<boolean>,
	hovered: source<boolean>,
}
export type arguments = {
    text: string,
    index: value<any>,
    noButton: boolean?,
    noPreview: boolean?,
}

return ui.widget("dropdown", function(arguments: partial<arguments>?)
	local args = root.default(arguments, { text = "dropdown" }) :: arguments
    local clicked = root.event()

	local state: state = {
		opened = root.source(false),
		hovered = root.source(false),
	}

    local content_size = config.textSize
    local size = content_size + config.padding * 2
    local preview = root.create("TextLabel") {
        Text = tostring(root.read(args.index)),
        Size = UDim2.new(config.dropdown_width, 0, 0, size),
    
        ui.padding(config.padding),
        ui.hovered(state.hovered),
        ui.constrain(100, nil, nil, nil),

        paint.text(),
        paint.dropdown(state.hovered),

        ui.clicked("Button1", function()
            state.opened(not state.opened())
            clicked.fire()
        end),
    } :: TextLabel

    local button = root.create("Frame") {
        AnchorPoint = Vector2.new(1, 0.5),

        Position = UDim2.new(1, config.padding, 0.5, 0),
        Size = function()
            local size = preview.AbsoluteSize
            return UDim2.fromOffset(size.Y, size.Y)
        end,
    
        paint.button(state.hovered),

        root.create("ImageLabel") {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,

            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(content_size, content_size),

            Image = assets.downPointingTriangle,

            paint.image(),
        },
    }

    local contents = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0, preview.AbsoluteSize.X, 0, 0),

        Visible = state.opened,
        Position = function()
            local px = preview.AbsolutePosition.X
            local py = preview.AbsolutePosition.Y
            local sy = preview.AbsoluteSize.Y

            return UDim2.fromOffset(px, py + sy)
        end,

        paint.tooltip(),

        ui.padding(config.padding),
        ui.list_layout("Vertical", 0),
    } :: Frame

    local timer = root.source(-1)
    local delay = 2

    if state.opened() and root.mouse_clicked("Button1") then
        timer( root.get_tick() + delay )
    end

    if timer() == root.get_tick() then
        state.opened(false)
        timer(-1)
    end

    row({ fixed_size = true }).with(function()
        ui.mount(button, preview)
        ui.mount(preview)

        text { text = args.text }
    end)
    ui.mount(contents, "root")
    return ui.start_scope(contents, state)
end)

