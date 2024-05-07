class_name CameraOrbit3D
extends Node3D

const MOUSE_SENS : float = 0.25

@onready var pivot_vert = $"Pivot Vert"

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		
		pivot_vert.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		pivot_vert.rotation.x = clamp(pivot_vert.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
		rotation.z = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
