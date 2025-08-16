local color4 = require("./utils/color4")

return {
	colors = {
		Border = color4.create(160, 160, 175, 0.7),
		BorderDark = color4.create(110, 110, 125, 0.5),

		Text = color4.create(255, 255, 255, 1),
		TextDisabled = color4.create(128, 128, 128, 1),

		ResizeGrip = color4.create(66, 150, 250, 0.2),
		ResizeGripHovered = color4.create(66, 150, 250, 0.67),
		
		WindowBg = color4.create(15, 15, 15, 0.94),
		WindowBgCollapsed = color4.create(15, 15, 15, 0),
		
		TitleBg = color4.create(41, 74, 122, 1),
		TitleBgDisabled = color4.create(10, 10, 10, 1),
		TitleBgCollapsed = color4.create(0, 0, 0, 0.6),

        Menubar = color4.create(36, 36, 36, 1),
		MenuButton = color4.create(36, 36, 36, 1),
		MenuButtonHovered = color4.create(41, 74, 122, 0.54),
		MenuButtonSelected = color4.create(66, 150, 250, 0.4),
		
		Button = color4.create(66, 150, 250, 0.4),
		ButtonHovered = color4.create(66, 150, 250, 0.6),
		ButtonActive = color4.create(15, 135, 250, 1),
		
		FrameBg = color4.create(41, 74, 122, 0.54),
		FrameBgHovered = color4.create(66, 150, 250, 0.54),
		FrameBgActive = color4.create(15, 135, 250, 0.67),

		Header = color4.create(66, 150, 250, 0.31),
		HeaderHovered = color4.create(66, 150, 250, 0.62),
		HeaderActive = color4.create(15, 135, 250, 1),

        Tooltip = color4.create(20, 20, 20, 0.94),
		Seperator = color4.create(99, 99, 99, 0.62),
		RadialCenter = color4.create(66, 150, 250, 1),

		Image = color4.create(255, 255, 255, 1),
	},
	assets = {
		rightPointingTriangle = "rbxasset://textures/DeveloperFramework/button_arrow_right.png",
		downPointingTriangle = "rbxasset://textures/DeveloperFramework/button_arrow_down.png",
		xCloseIcon = "rbxasset://textures/AnimationEditor/icon_close.png", -- best approximation for a close X which roblox supports, needs to be scaled about 2x
		bottomRightCorner = "rbxasset://textures/ui/InspectMenu/gr-item-selector-triangle.png", -- used in window resize icon in bottom right
		checkMark = "rbxasset://textures/AnimationEditor/icon_checkmark.png",
		placeholderImage = "rbxasset://textures/ui/GuiImagePlaceholder.png",
	},
	
	font = Enum.Font.RobotoMono,
	minWindowSize = vector.create(200, 100),
	cornerRadius = 5,
	textSize = 14,
	rowHeight = 16,
	strokeThickness = 1.5,

	spacing = 8,
	padding = 4,
	
	default_value_increment = 0.1,
	drag_delay = 0.3,
	drag_sensitivity = 10,
}