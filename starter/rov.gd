extends CharacterBody3D
## The robot: driving, bumping into things, and the camera that follows it.
## You do not need to edit this file.

const SPEED := 11.0
const LIFT := 7.0
const TURN := 1.7
const EDGE := 78.0
const CEILING := 29.0

var terrain: Node
var turn_speed := 0.0
var propellers: Array[Node3D] = []

@onready var camera: Camera3D = $"../ChaseCamera"


func _ready() -> void:
	_build_model()


func place(spot: Vector3) -> void:
	position = spot
	velocity = Vector3.ZERO
	camera.global_position = _camera_spot()


func _physics_process(delta: float) -> void:
	var drive := _axis([KEY_W, KEY_UP], [KEY_S, KEY_DOWN])
	var turn := _axis([KEY_A, KEY_LEFT], [KEY_D, KEY_RIGHT])
	var lift := _axis([KEY_SPACE, KEY_E], [KEY_SHIFT, KEY_Q])

	turn_speed = lerpf(turn_speed, turn * TURN, 1.0 - exp(-6.0 * delta))
	rotate_y(turn_speed * delta)
	var target := -transform.basis.z * drive * SPEED + Vector3.UP * lift * LIFT
	velocity = velocity.lerp(target, 1.0 - exp(-3.0 * delta))
	move_and_slide()

	position.x = clampf(position.x, -EDGE, EDGE)
	position.z = clampf(position.z, -EDGE, EDGE)
	var floor_y := -INF
	if terrain != null:
		floor_y = terrain.height_at(position.x, position.z) + 0.6
	position.y = clampf(position.y, floor_y, CEILING)

	$Model.rotation.x = lerpf($Model.rotation.x, -drive * 0.12 + lift * 0.1, 1.0 - exp(-4.0 * delta))
	$Model.rotation.z = lerpf($Model.rotation.z, turn * 0.2, 1.0 - exp(-4.0 * delta))
	for p in propellers:
		p.rotate_z((4.0 + velocity.length() * 3.0) * delta)

	camera.global_position = camera.global_position.lerp(_camera_spot(), 1.0 - exp(-5.0 * delta))
	if terrain != null:
		var eye := camera.global_position
		camera.global_position.y = maxf(eye.y, terrain.height_at(eye.x, eye.z) + 1.2)
	camera.look_at(global_position - transform.basis.z * 4.0)


func _camera_spot() -> Vector3:
	return global_position + transform.basis.z * 6.5 + Vector3.UP * 2.6


func _axis(plus: Array, minus: Array) -> float:
	var value := 0.0
	if plus.any(Input.is_physical_key_pressed):
		value += 1.0
	if minus.any(Input.is_physical_key_pressed):
		value -= 1.0
	return value


func _build_model() -> void:
	var yellow := Color(1.0, 0.78, 0.1)
	var dark := Color(0.12, 0.13, 0.17)
	_box(Vector3(1.3, 0.35, 1.5), Vector3(0, 0.35, 0), yellow)
	_box(Vector3(0.9, 0.5, 1.2), Vector3(0, -0.05, 0), dark)
	for side in [-1.0, 1.0]:
		_box(Vector3(0.1, 0.12, 1.6), Vector3(side * 0.6, -0.5, 0), dark)
		for z in [-0.5, 0.5]:
			_box(Vector3(0.08, 0.8, 0.08), Vector3(side * 0.6, -0.1, z), dark)
		_box(Vector3(0.2, 0.16, 0.1), Vector3(side * 0.35, 0.05, -0.75), Color(1, 1, 0.85), true)
		var hub := Node3D.new()
		hub.position = Vector3(side * 0.4, 0.0, 0.75)
		$Model.add_child(hub)
		propellers.append(hub)
		for angle in [0.0, PI / 2.0]:
			var blade := _box(Vector3(0.42, 0.07, 0.03), Vector3.ZERO, Color(0.75, 0.78, 0.82))
			blade.reparent(hub, false)
			blade.rotation.z = angle
	_box(Vector3(0.36, 0.36, 0.1), Vector3(0, -0.05, -0.65), Color(0.2, 0.7, 1.0), true)


func _box(size: Vector3, spot: Vector3, color: Color, glows := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	if glows:
		mat.emission_enabled = true
		mat.emission = color
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = spot
	$Model.add_child(node)
	return node
