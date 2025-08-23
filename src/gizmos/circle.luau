--!strict
local config = require("../config")
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

type arguments = {
	radius: number,
	transform: CFrame,
	
	subdivisions: number?,
	angle: number?,
	close_shape: boolean?,
}

return gizmo.create("circle", function(arguments: arguments)
	local args = root.default(arguments, {
		subdivisions = config.gizmo.defaultSubdivision,
		angle = 360,
	}) :: root.dissolve<arguments>
	
	args.angle %= 361
	if args.angle < 360 then
		args.close_shape = false
	else
		args.close_shape = true
	end
	
	local angle_step = args.angle / args.subdivisions
	local total_angle = 0
	
	local vertices = {}
	for i=1, args.subdivisions do
		local px = math.sin( math.rad(total_angle) ) * args.radius
		local py = math.cos( math.rad(total_angle) ) * args.radius
		
		local vertex = args.transform:PointToWorldSpace( Vector3.new(px, 0, py) )
		
		table.insert(vertices, vertex)
		total_angle += angle_step
	end
	
	gizmo.draw_path(vertices, args.close_shape)
end)