class_name Character3DMovement
extends CharacterBody3D

@export_category("Ground Movement")
@export var walk_speed : float = 3.0
@export var run_speed : float = 5.0
@export var jump_strength : float = 4.5
@export var coyote_time : float = 0.15
@export var acceleration : float = 7.0
@export var deceleration : float = 12.0
@export var change_direction_strength : float = 4.0

@export_category("Air Movement")
@export var air_control : float = 0.5
@export var air_drag : float = 4.0

@export_category("Character Visuals")
@export var rotate_towards_movement : bool = true
@export var rotation_rate : float = 4.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var desired_velocity : Vector3 = Vector3.ZERO
var off_ground_time : float = 0.0
var target_speed : float = 0.0

@onready var camera : Camera3D = find_children("", "Camera3D")[0]
@onready var visual : MeshInstance3D = find_children("", "MeshInstance3D")[0]

func _input(_event):
	if Input.is_key_pressed(KEY_ESCAPE): get_tree().quit()
	
func _process(_delta):
	DebugDraw3D.draw_arrow(global_position, global_position + -visual.global_basis.z, Color.BLUE)

func _physics_process(delta):
	desired_velocity.x = velocity.x
	desired_velocity.y = 0
	desired_velocity.z = velocity.z
	
	# Add the gravity.
	if is_on_floor():
		target_speed = run_speed if Input.is_action_pressed("sprint") else walk_speed
		off_ground_time = 0
	else:
		off_ground_time += delta
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() || off_ground_time < coyote_time):
		velocity.y = jump_strength

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var dir = (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y)).limit_length()
	
	if dir:
		var change = acceleration if is_on_floor() else acceleration * air_control
		var similar : float = clamp(dir.dot(velocity), -1.0, 1.0)
		
		if similar < 0.5:
			var multiplier : float = ((1.0 + similar) / 2.0) + 1.0
			change *= multiplier * change_direction_strength
			
		
		desired_velocity = desired_velocity.move_toward(dir * target_speed, delta * change)
	else:
		var change = deceleration if is_on_floor() else air_drag
		desired_velocity = desired_velocity.move_toward(Vector3.ZERO, delta * change)

	desired_velocity.y = velocity.y
	velocity = desired_velocity
	
	if rotate_towards_movement && visual && input_dir.length_squared() > 0.001:
		var target_vector = global_position.direction_to(global_position + dir)
		target_vector.y = 0
		var target_basis = visual.basis.looking_at(target_vector)
		visual.basis = visual.basis.slerp(target_basis, delta * rotation_rate)
	
	move_and_slide()
