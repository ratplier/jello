--!strict
local root = require("../../utils/rootkit")
local ui = require("../../utils/uikit")

type source<T> = root.source<T>
type partial<T> = root.partial<T>

export type arguments = {
	height: number,
	padding: number,
}

return ui.widget("row", function(arguments: root.partial<arguments>?)
	local args = root.default(arguments, { height = 16, padding = 8 }) :: arguments

	local object = root.create("Frame") {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, args.height),

		ui.list_layout("Horizontal", args.padding),
	}

	root.mount(object)
	return ui.start_scope(object)
end)
