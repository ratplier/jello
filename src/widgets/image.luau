--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local ui = require("../utils/uikit")
local paint = require("../utils/paint")

local assets = config.assets

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type state = {
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

return ui.widget("image", function(arguments: partial<arguments>?)
	local args = root.default(arguments, {
		image_id = assets.placeholderImage, padding = config.padding,
		size = Vector2.new(32, 32),
		scale_type = "Fit",
		resample_mode = "Default",
	}) :: arguments
	
	local state: state = {
		hovered = root.source(false),
	}
	
	ui.mount(function()
		return root.create("ImageLabel") {
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
			
			ui.padding(args.padding),
			ui.hovered(state.hovered),
		}
	end)
	
	return state
end)

