--!strict
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")
local paint = require("../../utils/paint")
local config = require("../../config")

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

type state = {}
export type arguments = {
    title: string,
    header: boolean,
}

return ui.widget("header", function(arguments: partial<arguments>?)
    local args = root.default(arguments, { title = "Header", header = false, }) :: arguments
    local clicked = root.event()

    local state = {
        collapsed = root.source(false),
        hovered = root.source(false),
        clicked = clicked.fired,
    }

    local content_height = config.textSize - 1.5
    local header_size = 18
    local contents = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,

        Position = UDim2.fromOffset(0, header_size + 5),
        Size = UDim2.fromScale(1, 0),

        Visible = not state.collapsed(),

        ui.list_layout("Vertical", 5),
    }

    local object = root.create("Frame") {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, header_size),

        ui.padding(5),

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
                clicked.fire()
            end),
        },

        root.create("TextLabel") {
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,

            Position = UDim2.new(0, header_size + 5, 0, header_size / 4),
            LayoutOrder = 2,

            Text = args.title,
            paint.text(true),

            ui.clicked("Button1", function()
                state.collapsed(not state.collapsed())
                clicked.fire()
            end),
        },
        
        contents,
        paint.header(state.clicked, state.hovered, args.header),

        ui.hovered(state.hovered),
    }

    root.mount(object)
    return ui.start_scope(contents, {})
end)

