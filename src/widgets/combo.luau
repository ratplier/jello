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
    selected: source<any>,
    clicked: source<boolean>,
}

export type arguments = {
    text: string?,
    options: { any },
    selected: value<any>?,
    noButton: boolean?,
    noPreview: boolean?,
}

return ui.widget("combo", function(arguments: partial<arguments>?)
    local args = root.default(arguments, { 
        text = "combo",
        options = {},
    }) :: arguments
    
    local last_click = root.source(root.get_tick())
    
    local state: state = {
        opened = root.source(false),
        hovered = root.source(false),
        selected = args.selected or root.source(if #args.options > 0 then args.options[1] else nil),
        clicked = root.derive(function()
            return last_click() >= root.get_tick()
        end),
    }
    
    local content_size = config.textSize
    local size = content_size + config.padding * 2
    
    local preview = root.create("TextLabel") {
        Text = function()
            local selected = state.selected()
            return if selected then tostring(selected) else "Select..."
        end,
        Size = UDim2.new(config.dropdown_width, 0, 0, size),
        
        ui.padding(config.padding),
        ui.hovered(state.hovered),
        ui.constrain(100, nil, nil, nil),
        
        paint.text(),
        paint.dropdown(state.hovered),
        
        ui.clicked("Button1", function()
            state.opened(not state.opened())
            last_click(root.get_tick())
        end),
    } :: TextLabel
    
    local button = if not args.noButton then root.create("Frame") {
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
    } else nil
    
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
    
    for _, option in args.options do
        local option_button = root.create("TextButton") {
            Text = tostring(option),
            Size = UDim2.new(1, 0, 0, content_size + config.padding),
            BackgroundTransparency = 1,
            
            ui.padding(config.padding / 2),
            paint.text(),
            
            ui.clicked("Button1", function()
                state.selected(option)
                state.opened(false)
                last_click(root.get_tick())
            end),
        } :: TextButton
        
        ui.hovered(function(hovered)
            if hovered then
                option_button.BackgroundTransparency = 0.9
            else
                option_button.BackgroundTransparency = 1
            end
        end)(option_button)
        
        ui.mount(option_button, contents)
    end
    
    local timer = root.source(-1)
    local delay = 2
    
    if state.opened() and root.mouse_clicked("Button1") then
        timer(root.get_tick() + delay)
    end
    
    if timer() == root.get_tick() then
        state.opened(false)
        timer(-1)
    end
    
    row({ fixed_size = true }).with(function()
        if button then
            ui.mount(button, preview)
        end
        ui.mount(preview)
        
        if args.text then
            text { text = args.text }
        end
    end)
    
    ui.mount(contents, "root")
    return state
end)
