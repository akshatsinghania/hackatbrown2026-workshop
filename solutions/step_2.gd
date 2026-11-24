extends "res://starter/reef_base.gd"

var hills = FastNoiseLite.new()
var ridges = FastNoiseLite.new()


func setup(reef_seed):
	hills.seed = reef_seed
	hills.frequency = 0.02
	hills.fractal_octaves = 4

	ridges.seed = reef_seed + 1
	ridges.frequency = 0.008
	ridges.fractal_octaves = 1


func get_height(x, z):
	var height = hills.get_noise_2d(x, z) * 14.0
	var ridge = 1.0 - abs(ridges.get_noise_2d(x, z))
	height += pow(ridge, 4) * 10.0
	return height
