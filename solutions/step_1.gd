extends "res://starter/reef_base.gd"

var hills = FastNoiseLite.new()


func setup(reef_seed):
	hills.seed = reef_seed
	hills.frequency = 0.02
	hills.fractal_octaves = 4


func get_height(x, z):
	var height = hills.get_noise_2d(x, z) * 14.0
	return height
