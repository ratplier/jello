--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

local circle = require("./circle")

type arguments = {
	radius: number,
	transform: CFrame,
	subdivisions: number?,
}

return gizmo.create("sphere", function(arguments: arguments)
	local args = root.default(arguments, {
		subdivisions = config.gizmo.defaultSubdivision,
	}) :: root.dissolve<arguments>
	
	circle({
		radius = args.radius,
		transform = args.transform,
		subdivisions = args.subdivisions,
	})

	circle({
		radius = args.radius,
		transform = args.transform * CFrame.Angles(math.rad(90), 0, 0),
		subdivisions = args.subdivisions,
	})

	circle({
		radius = args.radius,
		transform = args.transform * CFrame.Angles(0, 0, math.rad(90)),
		subdivisions = args.subdivisions,
	})
end)