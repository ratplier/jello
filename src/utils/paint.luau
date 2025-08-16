--!strict
local ui = require("./uikit")
local root = require("./rootkit")
local config = require("../config")
local color4 = require("./color4")

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
        TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
        
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
            if read(collapsed) == true then colors.TitleBgCollapsed
            elseif read(active) == true then colors.TitleBg
            else colors.TitleBgDisabled
    end)
end

function paint.header(clicked: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(clicked) == true then colors.HeaderActive
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
    return {
        ui.apply_color("Background", function()
            return
                if read(collapsed) == true then colors.WindowBgCollapsed
                else colors.WindowBg
        end),

        root.create("UIStroke") {
            Thickness = config.strokeThickness,

            Color = color4.read_color3(colors.BorderDark),
            Transparency = color4.read_alpha(colors.BorderDark),
        },
    }
end

function paint.tooltip()
    return {
        ui.apply_color("Background", colors.Tooltip),
        root.create("UIStroke") {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = config.strokeThickness,

            Color = color4.read_color3(colors.Border),
            Transparency = color4.read_alpha(colors.Border),
        },
    }
end

function paint.menubar()
    return ui.apply_color("Background", colors.Menubar)
end

function paint.menu(selected: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(selected) == true then colors.MenuSelected
            elseif read(hovered) == true then colors.MenuHovered
            else colors.Menu
    end)
end

function paint.menuitem(active: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(active) == true then colors.MenuItemActive
            elseif read(hovered) == true then colors.MenuItemHovered
            else colors.MenuItem
    end)
end

function paint.no_background()
    return {
        BackgroundTransparency = 1,
    }
end

function paint.image()
    return {
        ScaleType = Enum.ScaleType.Fit,
        ui.apply_color("Image", colors.Image)
    }
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

function paint.option(selected: value<boolean>?, active: value<boolean>?, hovered: value<boolean>?)
    return ui.apply_color("Background", function()
        return
            if read(active) == true then colors.FrameBgActive
            elseif read(hovered) == true then colors.FrameBgHovered
            elseif read(selected) == true then colors.FrameBg
            else color4.create(0, 0, 0, 0)
    end)
end

return paint