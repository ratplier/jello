--!strict
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

type vec3 = gizmo.vec3
type arguments = {
	origin: vec3,
	target: vec3,
}

return gizmo.create("line", function(arguments: arguments)
	local args = root.default(arguments, {}) :: arguments
	gizmo.draw_line(
		arguments.origin :: Vector3,
		arguments.target :: Vector3
	)
end)