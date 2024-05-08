class_name CameraOrbit3D
extends Node3D

@export_category("Mouse Settings")
@export var mouse_sensitivity : Vector2 = Vector2(3.0, 3.0)

@export_category("Orbit Settings")
@export var pitch_limit : Vector2 = Vector2(-90, 90)
@export var distance : float = 3.0
@export var lateral_offset : float = 0.0

@onready var pivot : Node3D = get_parent()
var mouse_input : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	position = Vector3(lateral_offset, 0, distance)

func _input(event):
	if event is InputEventMouseMotion:
		pivot.rotation.x -= event.relative.y * mouse_sensitivity.y * 0.001
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(pitch_limit.x), deg_to_rad(pitch_limit.y))
		pivot.rotation.y -= event.relative.x * mouse_sensitivity.x * 0.001
		mouse_input = event.relative

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
