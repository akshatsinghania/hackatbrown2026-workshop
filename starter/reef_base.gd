extends RefCounted
## What every reef can do. reef.gd replaces these functions with its own.
## You do not need to edit this file.


## Called once, before the reef is built. Set up your noise here.
func setup(_reef_seed: int) -> void:
	pass


## How high is the seabed at (x, z), in metres?
## x and z run from -80 to 80. The water surface is at 30.
func get_height(_x: float, _z: float) -> float:
	return 0.0


## What grows at (x, z)? Return "branch", "brain", "tube", "fan", "kelp",
## "rock", or "" for nothing.
func get_coral(_x: float, _z: float, _height: float) -> String:
	return ""


## What colour is the seabed here? slope: 0 = flat, 1 = cliff.
func get_color(_x: float, _z: float, height: float, slope: float) -> Color:
	var sand := Color(0.86, 0.76, 0.55).lerp(Color(0.95, 0.88, 0.7), clampf(height / 12.0, 0, 1))
	return sand.lerp(Color(0.56, 0.5, 0.56), smoothstep(0.2, 0.55, slope))
