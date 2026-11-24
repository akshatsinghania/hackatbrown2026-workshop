extends StaticBody3D
## Asks get_coral() what grows at each spot, then plants it.
## You do not need to edit this file.

const STEP := 2 # one possible coral every 2 metres
const KINDS := {
	"branch": [Color(1.0, 0.42, 0.45), Color(1.0, 0.62, 0.3), Color(0.95, 0.4, 0.75)],
	"brain": [Color(0.6, 0.8, 0.35), Color(0.9, 0.75, 0.3), Color(0.35, 0.75, 0.65)],
	"tube": [Color(0.6, 0.4, 0.95), Color(0.3, 0.6, 1.0), Color(0.85, 0.4, 0.95)],
	"fan": [Color(0.9, 0.25, 0.55), Color(0.65, 0.3, 0.85), Color(1.0, 0.5, 0.2)],
	"kelp": [Color(0.3, 0.6, 0.25), Color(0.45, 0.65, 0.2)],
	"rock": [Color(0.4, 0.4, 0.48), Color(0.5, 0.46, 0.45)],
}
# Solid kinds get a collision sphere this big. You can drive through the rest.
const SOLID := {"brain": 0.8, "rock": 0.9, "branch": 0.7, "tube": 0.6}

const SWAY_SHADER := "
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform float sway = 0.0;
void vertex() {
	vec3 base = MODEL_MATRIX[3].xyz;
	float bend = sway * VERTEX.y * VERTEX.y;
	VERTEX.x += sin(TIME * 1.3 + base.x * 0.4 + VERTEX.y * 0.6) * bend;
	VERTEX.z += cos(TIME * 1.1 + base.z * 0.4 + VERTEX.y * 0.6) * bend;
}
void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(1.5));
	ROUGHNESS = 1.0;
}
"

var total := 0
var unknown := ""
var meshes := {}
var layers := {}


func _ready() -> void:
	meshes = {
		"branch": _branch(), "brain": _ball(0.8, 0.55), "tube": _tubes(),
		"fan": _fan(), "kelp": _kelp(), "rock": _ball(0.9, 0.7),
	}
	for kind in KINDS:
		meshes[kind].surface_set_material(0, _material({"kelp": 0.02, "fan": 0.05}.get(kind, 0.0)))
		var layer := MultiMeshInstance3D.new()
		layer.name = kind.capitalize()
		layer.multimesh = MultiMesh.new()
		layer.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		layer.multimesh.use_colors = true
		layer.multimesh.mesh = meshes[kind]
		add_child(layer)
		layers[kind] = layer


func build(reef: RefCounted, terrain: Node) -> void:
	total = 0
	unknown = ""
	for id in get_shape_owners():
		remove_shape_owner(id)
	# Our own dice, so that looks never disturb randf() inside reef.gd.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spots := {}
	for kind in KINDS:
		spots[kind] = []
	var edge := int(terrain.HALF) - 2
	for gz in range(-edge, edge, STEP):
		for gx in range(-edge, edge, STEP):
			var x := gx + rng.randf_range(-0.8, 0.8)
			var z := gz + rng.randf_range(-0.8, 0.8)
			var h: float = terrain.height_at(x, z)
			var size := rng.randf_range(0.9, 2.0)
			var turn := rng.randf() * TAU
			var tint := rng.randf()
			var kind: String = reef.get_coral(x, z, h)
			if kind == "":
				continue
			if not KINDS.has(kind):
				unknown = kind
				continue
			var pose := Transform3D(Basis(Vector3.UP, turn).scaled(Vector3.ONE * size), Vector3(x, h - 0.1, z))
			spots[kind].append([pose, KINDS[kind][int(tint * KINDS[kind].size())]])
			if SOLID.has(kind):
				var ball := SphereShape3D.new()
				ball.radius = SOLID[kind] * size
				var id := create_shape_owner(self)
				shape_owner_add_shape(id, ball)
				shape_owner_set_transform(id, Transform3D(Basis(), Vector3(x, h + 0.3 * size, z)))
	for kind in KINDS:
		var mm: MultiMesh = layers[kind].multimesh
		mm.instance_count = spots[kind].size()
		for n in spots[kind].size():
			mm.set_instance_transform(n, spots[kind][n][0])
			mm.set_instance_color(n, spots[kind][n][1])
		total += spots[kind].size()


func _material(sway: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SWAY_SHADER
	mat.set_shader_parameter("sway", sway)
	return mat


# --- Shapes, all made in code so there is nothing to download ---

func _join(parts: Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		tool.append_from(part[0], 0, part[1])
	return tool.commit()


func _ball(radius: float, squash: float) -> ArrayMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 10
	s.rings = 5
	return _join([[s, Transform3D(Basis().scaled(Vector3(1, squash, 1)), Vector3(0, 0.15, 0))]])


func _stick(bottom: float, top: float, length: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = bottom
	c.top_radius = top
	c.height = length
	c.radial_segments = 5
	c.rings = 0
	return c


func _lean(angle: float, tilt: float, start: float, length: float) -> Transform3D:
	var basis := Basis(Vector3.UP, angle) * Basis(Vector3.RIGHT, tilt)
	return Transform3D(basis, Vector3(0, start, 0) + basis.y * length * 0.5)


func _branch() -> ArrayMesh:
	var parts := [[_stick(0.16, 0.1, 0.9), _lean(0, 0, 0, 0.9)]]
	for n in 7:
		parts.append([_stick(0.11, 0.04, 1.1), _lean(n * TAU / 7.0, 0.6 + 0.25 * (n % 2), 0.15 + 0.08 * n, 1.1)])
	return _join(parts)


func _tubes() -> ArrayMesh:
	var parts := []
	for n in 6:
		var length := 0.8 + 0.25 * (n % 3)
		parts.append([_stick(0.14, 0.22, length), _lean(n * TAU / 6.0, 0.28, 0, length)])
	return _join(parts)


func _fan() -> ArrayMesh:
	var parts := []
	for n in 9:
		var angle := (n - 4) * 0.26
		var length := 1.8 - 0.06 * absf(n - 4) * absf(n - 4)
		var basis := Basis(Vector3.BACK, angle)
		parts.append([_stick(0.06, 0.09, length), Transform3D(basis, basis.y * length * 0.5)])
	return _join(parts)


func _kelp() -> ArrayMesh:
	var parts := []
	for n in 4:
		var blade := BoxMesh.new()
		blade.size = Vector3(0.22, 5.0 + n, 0.03)
		blade.subdivide_height = 8
		parts.append([blade, Transform3D(Basis(Vector3.UP, n * 0.9), Vector3(cos(n * 1.6) * 0.3, (5.0 + n) / 2.0, sin(n * 1.6) * 0.3))])
	return _join(parts)
