--!strict
local config = require("../../config")
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type arguments = {
	align: "Left" | "Center" | "Right",
	padding: number,
}

return ui.widget("group", function(arguments: root.partial<arguments>?)
	local args = root.default(arguments, { align = "Left", padding = config.spacing }) :: arguments

	local alignment = Enum.HorizontalAlignment:FromName(args.align) :: Enum.HorizontalAlignment
	local list = ui.list_layout("Vertical", args.padding) :: UIListLayout
	list.HorizontalAlignment = alignment

	local object = root.create("Frame") {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),

		list,
	}

	ui.mount(object)
	return ui.start_scope(object)
end)
