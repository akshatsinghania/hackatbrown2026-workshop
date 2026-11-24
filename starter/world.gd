extends Node3D
## Builds the reef from reef.gd. You do not need to edit this file.

const WATER_LEVEL := 30.0
const DEFAULT_REEF := "res://reef.gd"

var reef: RefCounted
var reef_seed := 1
var reef_path := DEFAULT_REEF
var map_view := false

@onready var terrain = $Terrain
@onready var corals = $Corals
@onready var fish = $Fish
@onready var rov = $ROV


func _ready() -> void:
	# Presenter: "godot --path . -- --reef=res://solutions/step_3.gd" runs a solution.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reef="):
			reef_path = arg.trim_prefix("--reef=")
	_add_marine_snow()
	rebuild()
	rov.place(Vector3(0, terrain.height_at(0, 0) + 4.0, 0))


func rebuild() -> void:
	# Reading the file from disk again means: save reef.gd, press Enter, see it.
	var script := ResourceLoader.load(reef_path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
	if script == null or not script.can_instantiate():
		$HUD/Message.text = "reef.gd has an error. Look at the Output panel in Godot."
		if reef == null:
			reef = preload("res://starter/reef_base.gd").new()
			_build()
		return
	reef = script.new()
	_build()


func _build() -> void:
	var start := Time.get_ticks_msec()
	seed(reef_seed) # makes randf() in reef.gd repeat for the same seed
	reef.setup(reef_seed)
	terrain.build(reef)
	seed(reef_seed)
	corals.build(reef, terrain)
	fish.build(reef_seed, terrain)
	rov.terrain = terrain
	if rov.position.y < terrain.height_at(rov.position.x, rov.position.z) + 2.0:
		rov.place(Vector3(rov.position.x, terrain.height_at(rov.position.x, rov.position.z) + 4.0, rov.position.z))
	$HUD/Message.text = "Built in %d ms   |   %d corals" % [Time.get_ticks_msec() - start, corals.total]
	if corals.unknown != "":
		$HUD/Message.text += "   |   Unknown coral name: \"%s\"" % corals.unknown


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_R:
			reef_seed = Time.get_ticks_usec() % 100000
			rebuild()
		KEY_ENTER, KEY_KP_ENTER:
			rebuild()
		KEY_M:
			set_map_view(not map_view)


func set_map_view(on: bool) -> void:
	map_view = on
	$MapCamera.current = on
	$ChaseCamera.current = not on
	$Water.environment.fog_enabled = not on


func _process(_delta: float) -> void:
	$HUD/Info.text = "SEED %d     DEPTH %.1f m     %d FPS\nW/S drive   A/D turn   Space up   Shift down\nR new reef   Enter reload reef.gd   M map" % [
		reef_seed, WATER_LEVEL - rov.position.y, Engine.get_frames_per_second()]


func _add_marine_snow() -> void:
	var snow := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.02
	mesh.height = 0.04
	mesh.radial_segments = 4
	mesh.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.8, 0.95, 1.0)
	mesh.material = mat
	snow.mesh = mesh
	snow.amount = 150
	snow.lifetime = 8.0
	snow.preprocess = 8.0
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(18, 10, 18)
	snow.gravity = Vector3(0, -0.02, 0)
	snow.initial_velocity_max = 0.3
	snow.spread = 180.0
	snow.local_coords = false
	rov.add_child(snow)
