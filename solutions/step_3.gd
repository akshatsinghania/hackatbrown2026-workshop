extends "res://starter/reef_base.gd"

var hills = FastNoiseLite.new()
var ridges = FastNoiseLite.new()
var growth = FastNoiseLite.new()


func setup(reef_seed):
	hills.seed = reef_seed
	hills.frequency = 0.02
	hills.fractal_octaves = 4

	ridges.seed = reef_seed + 1
	ridges.frequency = 0.008
	ridges.fractal_octaves = 1

	growth.seed = reef_seed + 2
	growth.frequency = 0.04


func get_height(x, z):
	var height = hills.get_noise_2d(x, z) * 14.0
	var ridge = 1.0 - abs(ridges.get_noise_2d(x, z))
	height += pow(ridge, 4) * 10.0
	return height


func get_coral(x, z, height):
	var life = growth.get_noise_2d(x, z)
	if life < 0.0 or randf() > 0.6:
		return ""
	if height < 2.0:
		return "kelp"
	if life > 0.25:
		return ["branch", "fan", "tube"].pick_random()
	return ["brain", "rock"].pick_random()
