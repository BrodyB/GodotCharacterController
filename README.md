# 🏃 Godot Character Controller
This is a general purpose kinematic character controller for Godot 4.2 that acts as a starting place for creating a first- or third-person player.


![Version](https://img.shields.io/badge/Version-0.1-blue)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Still early with a lot of features and tweaks to come.

## Setup
There is no example scene in this repo at the moment, just the GDScripts.

```
🏃 Player [CharacterBody3D]      <- character_movement.gd
- Collider [CollisionShape3D]    <- Should have CapsuleShape3D
- Pivot [Node3D]                 <- Center on player, raise if you want pivot higher
    - Camera [Camera]            <- camera_orbit.gd
```

## Feature Roadmap
- ✔️ Walking / Sprinting
- ✔️ Walk up/down Slopes and Stairs
- ✔️ Jumping
- ✔️ Air Control
- ✔️ Third-Person Orbit Camera
	- ✔️ Lateral offsetting
	- 🚧 Camera wobble on move
	- 🚧 Position / Distance Lag as player moves around
- 🚧 First-Person Camera
- 🚧 Modularization
- 🚧 Crouching
- 🚧 Ledge Pull-up
- 🚧 Moving Platforms
- 🚧 Ladder Climbing
- 🚧 Swimming