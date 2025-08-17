--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	open: source<boolean>,
    clicked: source<boolean>,
    hovered: source<boolean>,
}
export type arguments = {
	text: string,
}

local function header(args: arguments, state: state)
    local content_size = config.textSize
    local clicked = root.event()
    state.clicked(clicked.fired())

    return root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, content_size),
        LayoutOrder = 1,

        paint.header(state.clicked, state.hovered),
        ui.hovered(state.hovered),
        ui.padding(config.padding),
        ui.list_layout("Horizontal", config.padding),

        ui.clicked("Button1", function()
            state.open(not state.open())
            clicked.fire()
        end),

        root.create("ImageLabel") {
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(content_size, math.floor(content_size * 0.7)),
            paint.image(),

            Image = function()
                return
                    if state.open() then assets.downPointingTriangle
                    else assets.rightPointingTriangle
            end,
        },
        root.create("TextLabel") {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,

            Text = args.text,
            paint.text(),
        },
    }
end

local function contents(args: arguments, state: state)
    return root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Size = UDim2.fromScale(1, 0),
        Visible = state.open,

        paint.no_background(),
        ui.padding(config.padding / 2),
        ui.list_layout("Vertical", config.spacing),
    }
end

return ui.widget("header", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {}) :: arguments

	local state: state = {
        clicked = root.source(false),
        hovered = root.source(false),
		open = root.source(false),
	}

    local contents = contents(args, state)
    local main = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.fromScale(1, 0),

        contents,
        header(args, state),

        ui.list_layout("Vertical", config.padding),
        paint.no_background(),
    }
	
    ui.mount(main)
	return ui.start_scope(contents, state)
end)
