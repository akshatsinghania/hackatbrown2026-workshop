extends MultiMeshInstance3D
## Schools of fish circling the reef. You do not need to edit this file.

const SCHOOLS := 14
const PER_SCHOOL := 22

const SHADER := "
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
void vertex() {
	float radius = INSTANCE_CUSTOM.x;
	float speed = INSTANCE_CUSTOM.y;
	float phase = INSTANCE_CUSTOM.z;
	float a = TIME * speed + phase;
	VERTEX.x += sin(TIME * 9.0 + phase * 20.0 + VERTEX.z * 5.0) * 0.06;
	float c = cos(a);
	float s = sin(a);
	mat3 turn = mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));
	VERTEX = turn * VERTEX + vec3(c * radius, sin(a * 2.0) * 0.5, s * radius);
	NORMAL = turn * NORMAL;
}
void fragment() { ALBEDO = pow(COLOR.rgb, vec3(1.5)); }
"


func _ready() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nose := Vector3(0, 0, 0.35)
	var top := Vector3(0, 0.16, 0)
	var low := Vector3(0, -0.16, 0)
	var left := Vector3(-0.07, 0, 0)
	var right := Vector3(0.07, 0, 0)
	var back := Vector3(0, 0, -0.3)
	for face in [[nose, top, left], [nose, right, top], [nose, left, low], [nose, low, right],
			[back, left, top], [back, top, right], [back, low, left], [back, right, low],
			[back, Vector3(0, 0.16, -0.5), Vector3(0, -0.16, -0.5)]]:
		for point in face:
			tool.add_vertex(point)
	tool.generate_normals()
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER
	tool.set_material(mat)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = tool.commit()
	custom_aabb = AABB(Vector3(-100, -20, -100), Vector3(200, 60, 200))


func build(reef_seed: int, terrain: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = reef_seed
	var palette := [Color(1, 0.75, 0.15), Color(1, 0.4, 0.2), Color(0.4, 0.75, 1), Color(0.95, 0.95, 1)]
	multimesh.instance_count = SCHOOLS * PER_SCHOOL
	for s in SCHOOLS:
		var x := rng.randf_range(-60, 60)
		var z := rng.randf_range(-60, 60)
		var radius := rng.randf_range(3.0, 8.0)
		# Swim above the tallest ground on the circle, not just above its centre.
		var ground: float = terrain.height_at(x, z)
		for n in 12:
			var a := n * TAU / 12.0
			ground = maxf(ground, terrain.height_at(x + cos(a) * radius, z + sin(a) * radius))
		var speed := rng.randf_range(0.25, 0.5)
		var phase := rng.randf() * TAU
		for f in PER_SCHOOL:
			var n := s * PER_SCHOOL + f
			var spot := Vector3(x, minf(ground + 1.8 + rng.randf() * 2.0, 29.0), z)
			multimesh.set_instance_transform(n, Transform3D(Basis(), spot))
			multimesh.set_instance_color(n, palette[s % palette.size()])
			multimesh.set_instance_custom_data(n, Color(radius + rng.randf_range(-1.2, 1.2), speed, phase + rng.randf_range(-0.5, 0.5), 0))
