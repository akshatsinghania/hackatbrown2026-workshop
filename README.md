# Reef Explorer

Generate a 3D coral reef from noise, then drive a robot (ROV) through it.

Needs Godot 4.7, nothing else. It works offline. Import `project.godot`, then press Play (F5, or Cmd+B on Mac).

| Key | Does |
|---|---|
| W / S, A / D | drive, turn (arrow keys work too) |
| Space / Shift (or E / Q) | up / down |
| Enter | reload `reef.gd` (save it first) |
| R | new seed, new reef |
| M | map view |

## What you write

Only `reef.gd`. Everything in `starter/` is already done.

1. **Seabed**: noise becomes height.
2. **Ridges**: a second noise layer, folded into sharp crests.
3. **Life**: a third noise layer decides where coral, kelp and rock grow.

Stuck? Copy the whole of `solutions/step_1.gd`, `step_2.gd` or `step_3.gd` into `reef.gd`.

## Go further

- Terraces: `height = snapped(height, 3.0)`
- A canyon down the middle: `height -= 12.0 * exp(-x * x / 80.0)`
- An island: `height += 15.0 - Vector2(x, z).length() * 0.25`
- Paint it: write `get_color(x, z, height, slope)` and return a `Color`
- No coral on deep sand: change the rules in `get_coral`
