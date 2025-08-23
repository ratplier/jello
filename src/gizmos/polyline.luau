--!strict
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

type vec3 = gizmo.vec3
type arguments = {
	points: { vec3 },
	close: boolean?,
}

return gizmo.create("polyline", function(arguments: arguments)
	local args = root.default(arguments, {}) :: arguments
	gizmo.draw_path(
		arguments.points :: { Vector3 },
		arguments.close
	)
end)