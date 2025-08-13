--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type arguments = {
	height: number,
	padding: number,
	fixed_size: boolean,
}

return ui.widget("row", function(arguments: root.partial<arguments>?)
	local args = root.default(arguments, { height = config.rowHeight, padding = config.spacing }) :: arguments

	local mode = if args.fixed_size then "Y" else "XY"
	local object = root.create("Frame") {
		AutomaticSize = Enum.AutomaticSize:FromName(mode),
		BackgroundTransparency = 1,
		Size = function()
			local scale = args.fixed_size and 1 or 0
			return UDim2.new(scale, 0, 0, args.height)
		end,

		ui.list_layout("Horizontal", args.padding),
	}

	root.mount(object)
	return ui.start_scope(object)
end)
