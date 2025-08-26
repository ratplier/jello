local config = require("../config")
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

local circle = require("./circle")

type arguments = {
	transform: CFrame,
	radius: number,
	height: number,
	subdivisions: number?,
}

return gizmo.create("cone", function(arguments: arguments)
	local args = root.default(arguments, {
        subdivisions = config.gizmo.defaultSubdivision,
    }) :: root.dissolve<arguments>

    local tip = args.transform * Vector3.new(0, args.height, 0)

	local angle_step = 360 / args.subdivisions
	local total_angle = 0
	
    for i=1, args.subdivisions do
		local px = math.sin( math.rad(total_angle) ) * args.radius
		local py = math.cos( math.rad(total_angle) ) * args.radius

        gizmo.draw_line(
            tip,
            args.transform * Vector3.new(px, 0, py)
        )
        total_angle += angle_step
    end

    circle {
        transform = args.transform,
        radius = args.radius,
        subdivisions = args.subdivisions,
        angle = 360,
    }
end)
