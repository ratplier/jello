--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
	clicked: source<boolean>,
	right_clicked: source<boolean>,
	middle_clicked: source<boolean>,
	
	hovered: source<boolean>,
}
export type arguments = {
	image_id: string,
	padding: number,
	size: Vector2,
	rect: Rect?,
	scale_type: ("Fit" | "Crop" | "Fill" | "Stretch"),
	resample_mode: ("Default" | "Pixelated"),
	tile_size: Vector2?,
	slice_center: Vector2?,
	slice_scale: number?,
}

return ui.widget("image_button", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {
		image_id = assets.placeholderImage, padding = config.padding,
		size = Vector2.new(32, 32),
		scale_type = "Fit",
		resample_mode = "Default",
	}) :: arguments
	local last_clicked = root.source(-1)
	local last_right_clicked = root.source(-1)
	local last_middle_clicked = root.source(-1)
	
	local state: state = {
		hovered = root.source(false),
		clicked = root.derive(function() return last_clicked() >= root.get_tick() end),
		right_clicked = root.derive(function() return last_right_clicked() >= root.get_tick() end),
		middle_clicked = root.derive(function() return last_middle_clicked() >= root.get_tick() end),
	}
	
	local clicked = root.derive(function()
		return state.clicked() or state.right_clicked() or state.middle_clicked()
	end)
	
	root.mount(function()
		return root.create("ImageLabel") {
			Active = true,
			Size = UDim2.fromOffset(args.size.X, args.size.Y),

			Image = args.image_id,
			ImageRect = args.rect,
			ImageRectOffset = args.rect and Vector2.new(args.rect.Min.X, args.rect.Min.Y) or nil,
			ImageRectSize = args.rect and Vector2.new(args.rect.Max.X - args.rect.Min.X, args.rect.Max.Y - args.rect.Min.Y) or nil,
			ScaleType = Enum.ScaleType:FromName(args.scale_type),
			ResampleMode = args.resample_mode and Enum.ResamplerMode:FromName(args.resample_mode) or nil,
			TileSize = args.tile_size,
			SliceCenter = args.slice_center,
			SliceScale = args.slice_scale,
			
			paint.image(),
			paint.button(clicked, state.hovered),
			
			ui.padding(args.padding),
			ui.hovered(state.hovered),
			ui.clicked("Button1", function()
				last_clicked( root.get_tick() )
			end),
			ui.clicked("Button2", function()
				last_right_clicked( root.get_tick() )
			end),
			ui.clicked("Button3", function()
				last_middle_clicked( root.get_tick() )
			end)
		}
	end)
	
	return state
end)

