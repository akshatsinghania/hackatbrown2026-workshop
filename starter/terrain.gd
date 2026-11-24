extends StaticBody3D
## Turns get_height() into a mesh you can see and a shape you can bump into.
## You do not need to edit this file.

const SIZE := 160 # metres, and also squares, along each side
const HALF := SIZE / 2.0
const SIDE := SIZE + 1 # points along each side
const MIN_HEIGHT := -15.0
const MAX_HEIGHT := 25.0 # always leaves room to swim over the top

const SHADER := "
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float caustic(vec2 p, float t) {
	float a = sin(p.x + sin(p.y * 1.3 + t)) + sin(p.y * 1.1 + sin(p.x * 0.9 - t * 0.8));
	return pow(1.0 - abs(a) * 0.5, 6.0);
}
void fragment() {
	vec3 col = pow(COLOR.rgb, vec3(2.2));
	float grain = fract(sin(dot(floor(world.xz * 6.0), vec2(12.99, 78.23))) * 43758.5);
	float light = caustic(world.xz * 0.9, TIME * 1.2) * 0.35;
	ALBEDO = col * (0.94 + grain * 0.08 + light);
	ROUGHNESS = 1.0;
}
"

var heights := PackedFloat32Array()
var material: ShaderMaterial


func build(reef: RefCounted) -> void:
	heights.resize(SIDE * SIDE)
	for j in SIDE:
		for i in SIDE:
			heights[j * SIDE + i] = clampf(reef.get_height(i - HALF, j - HALF), MIN_HEIGHT, MAX_HEIGHT)

	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	points.resize(SIDE * SIDE)
	normals.resize(SIDE * SIDE)
	colors.resize(SIDE * SIDE)
	for j in SIDE:
		for i in SIDE:
			var n := j * SIDE + i
			var h := heights[n]
			var dx := heights[j * SIDE + mini(i + 1, SIZE)] - heights[j * SIDE + maxi(i - 1, 0)]
			var dz := heights[mini(j + 1, SIZE) * SIDE + i] - heights[maxi(j - 1, 0) * SIDE + i]
			var normal := Vector3(-dx, 2.0, -dz).normalized()
			points[n] = Vector3(i - HALF, h, j - HALF)
			normals[n] = normal
			colors[n] = reef.get_color(i - HALF, j - HALF, h, 1.0 - normal.y)
	for j in SIZE:
		for i in SIZE:
			var a := j * SIDE + i
			indices.append_array([a, a + 1, a + SIDE, a + 1, a + SIDE + 1, a + SIDE])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material == null:
		material = ShaderMaterial.new()
		material.shader = Shader.new()
		material.shader.code = SHADER
	mesh.surface_set_material(0, material)
	$Mesh.mesh = mesh

	var shape := HeightMapShape3D.new()
	shape.map_width = SIDE
	shape.map_depth = SIDE
	shape.map_data = heights
	$Collision.shape = shape


## Seabed height at any point, blended between the four nearest grid points.
func height_at(x: float, z: float) -> float:
	var fx := clampf(x + HALF, 0.0, SIZE - 0.001)
	var fz := clampf(z + HALF, 0.0, SIZE - 0.001)
	var i := int(fx)
	var j := int(fz)
	var top := lerpf(heights[j * SIDE + i], heights[j * SIDE + i + 1], fx - i)
	var bottom := lerpf(heights[(j + 1) * SIDE + i], heights[(j + 1) * SIDE + i + 1], fx - i)
	return lerpf(top, bottom, fz - j)
