--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

local circle = require("./circle")

type vec3 = gizmo.vec3
type arguments = {
	transform: CFrame,
	radius: number,
	height: number,
	subdivisions: number?,
}

return gizmo.create("cylinder", function(arguments: arguments)
	local args = root.default(arguments, {
		subdivisions = config.gizmo.defaultSubdivision,
	}) :: root.dissolve<arguments>

	local angle_step = 360 / args.subdivisions
    local half_height = Vector3.yAxis * (args.height / 2)
	local total_angle = 0

	for i = 1, args.subdivisions do
		local px = math.sin( math.rad(total_angle) ) * args.radius
		local py = math.cos( math.rad(total_angle) ) * args.radius
        local p = Vector3.new(px, 0, py)

        gizmo.draw_line(
            args.transform * (p + half_height),
            args.transform * (p - half_height)
        )
		total_angle += angle_step
	end

    local transfrom_top = args.transform * CFrame.new(half_height)
    local transform_bottom = args.transform * CFrame.new(-half_height)

    circle {
        transform = transfrom_top,
        radius = args.radius,
        subdivisions = args.subdivisions,
        angle = 360,
    }

    circle {
        transform = transform_bottom,
        radius = args.radius,
        subdivisions = args.subdivisions,
        angle = 360,
    }
end)
