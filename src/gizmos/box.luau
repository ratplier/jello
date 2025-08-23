--!strict
local root = require("../utils/rootkit")
local gizmo = require("../utils/gizmo")

type vec3 = gizmo.vec3
type arguments = {
	transform: CFrame,
	size: vec3,
}

local edges = {
	{1, 2}, {2, 3}, {3, 4}, {4, 1},
	{5, 6}, {6, 7}, {7, 8}, {8, 5},
	
	{1, 5}, {2, 6}, {3, 7}, {4, 8}
}

return gizmo.create("box", function(arguments: arguments)
	local args = root.default(arguments, {}) :: arguments
	
	local transform = args.transform
	local size = args.size
	local halfSize = size :: Vector3 / 2

	local points = {
		Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z), -- 1
		Vector3.new( halfSize.X, -halfSize.Y, -halfSize.Z), -- 2
		Vector3.new( halfSize.X, -halfSize.Y,  halfSize.Z), -- 3
		Vector3.new(-halfSize.X, -halfSize.Y,  halfSize.Z), -- 4
		
		Vector3.new(-halfSize.X,  halfSize.Y, -halfSize.Z), -- 5
		Vector3.new( halfSize.X,  halfSize.Y, -halfSize.Z), -- 6
		Vector3.new( halfSize.X,  halfSize.Y,  halfSize.Z), -- 7
		Vector3.new(-halfSize.X,  halfSize.Y,  halfSize.Z)  -- 8
	}

	for _, edge in edges do
		local start = transform * points[edge[1]]
		local close = transform * points[edge[2]]
		gizmo.draw_line(start, close)
	end
end)