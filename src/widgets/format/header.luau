--!strict
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")
local config = require("../../config")

local assets = config.assets
local header_size = 18

type source<T> = root.source<T>
type partial<T> = root.partial<T>

type state = {
    collapsed: source<boolean>,
    hovered: source<boolean>,
    clicked: source<boolean>,
}
export type arguments = {
    title: string,
    header: boolean,
    padding: number,
}

local function contents(state: state, args: arguments)
    return root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,

        Position = UDim2.fromOffset(0, header_size),
        Size = UDim2.fromScale(1, 0),

        Visible = not state.collapsed(),

        ui.list_layout("Vertical", 0),
    }
end

local function header(state: state, args: arguments)
    local content_height = header_size / 2

    return root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,

        ui.list_layout("Horizontal", args.padding),

        root.create("ImageLabel") {
            Active = true,
            
            Size = UDim2.fromOffset(content_height, content_height),
            BackgroundTransparency = 1,
            LayoutOrder = 1,

            Image = function()
                return
                    if state.collapsed() then assets.rightPointingTriangle else
                    assets.downPointingTriangle
            end,

            paint.image(),
            ui.clicked("Button1", function()
                state.collapsed(not state.collapsed())
                state.clicked(true)
            end),
        },

        root.create("TextLabel") {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            LayoutOrder = 2,

            Text = args.title,
            paint.text(true),

            ui.clicked("Button1", function()
                state.collapsed(not state.collapsed())
                state.clicked(true)
            end),
        }
    }
end

return ui.widget("header", function(arguments: partial<arguments>?)
    local args = root.default(arguments, { title = "Header", padding = 5, header = false, }) :: arguments

    local clicked = root.event()
    local state: state = {
        collapsed = root.source(true),
        hovered = root.source(false),
        clicked = root.derive(clicked.fired),
    }

    local contents = contents(state, args)
    local object = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, header_size),

        contents,
        header(state, args),

        ui.padding(args.padding),
        ui.hovered(state.hovered),
    }

    root.mount(object)
    return ui.start_scope(contents, {})
end)

