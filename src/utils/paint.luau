--!strict
local ui = require("./uikit")
local root = require("./rootkit")
local config = require("../config")

type source<T> = root.source<T>
type value<T> = source<T> | T

local colors = config.colors
local read = root.read

local paint = {}

function paint.text(active: value<boolean>?)
    active = active or true
    return {
        Font = config.font,
        TextSize = config.textSize,
        ui.apply_color("Text", function()
            return
                if read(active) == true then colors.Text
                else colors.TextDisabled
        end),
    }
end

function paint.background(active: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(hovered) == true then colors.FrameBgHovered
            elseif read(active) == true then colors.FrameBgActive
            else colors.FrameBg
    end)
end

function paint.title(active: value<boolean>?, collapsed: value<boolean>?)
    active = active or true
    return ui.apply_color("Background", function()
        return
            if read(active) == true then colors.TitleBg
            elseif read(collapsed) == true then colors.TitleBgCollapsed
            else colors.TitleBgDisabled
    end)
end

function paint.header(clicked: value<boolean>?, hovered: value<boolean>?, header: boolean?)
    return ui.apply_color("Background", function()
        return
            if header ~= true then colors.NoHeader
            elseif read(clicked) == true then colors.HeaderActive
            elseif read(hovered) == true then colors.HeaderHovered
            else colors.Header
    end)
end

function paint.button(active: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(active) == true then colors.ButtonActive
            elseif read(hovered) == true then colors.ButtonHovered
            else colors.Button
    end)
end

function paint.window(collapsed: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(collapsed) == true then colors.WindowBgCollapsed
            else colors.WindowBg
    end)
end

function paint.image()
    return ui.apply_color("Image", colors.Image)
end

function paint.seperator()
    return ui.apply_color("Background", colors.Seperator)
end

function paint.resize_grip()
    return ui.apply_color("Image", colors.ResizeGrip)
end

function paint.radialcenter()
    return ui.apply_color("Background", colors.RadialCenter)
end

return paint