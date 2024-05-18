class_name Character3DMovement
extends CharacterBody3D

const EPSILON : float = 0.001

@export_category("Ground Movement")
@export var walk_speed : float = 3.0
@export var run_speed : float = 5.0
@export var jump_strength : float = 4.5
@export var coyote_time : float = 0.15
@export var acceleration : float = 7.0
@export var deceleration : float = 12.0
@export var change_direction_strength : float = 4.0
@export var step_height : float = 0.33

@export_category("Air Movement")
@export var air_control : float = 0.5
@export var air_drag : float = 4.0

@export_category("Character Visuals")
@export var rotate_towards_movement : bool = true
@export var rotation_rate : float = 4.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var desired_velocity : Vector3 = Vector3.ZERO
var off_ground_time : float = 0.0
var target_speed : float = 0.0
var collider_margin : float
var collider_height : float
var is_grounded : bool
var was_grounded : bool

@onready var camera : Camera3D = find_children("", "Camera3D")[0]
@onready var visual : MeshInstance3D = find_children("", "MeshInstance3D")[0]
@onready var collider : CollisionShape3D = find_children("", "CollisionShape3D")[0]

func _ready() -> void:
	collider_margin = collider.shape.margin
	var capsule = collider.shape as CapsuleShape3D
	collider_height = capsule.height * 0.5
	if collider_margin > 0.01:
		push_warning("Margin on player's collider shape is over 0.01, may snag on stair steps!")

func _input(_event) -> void:
	if Input.is_key_pressed(KEY_ESCAPE): get_tree().quit()
	
func _process(_delta) -> void:
	DebugDraw3D.draw_arrow(global_position, global_position + -visual.global_basis.z, Color.BLUE)

func _physics_process(delta) -> void:
	# Update grounded state
	was_grounded = is_grounded
	is_grounded = is_on_floor()
	
	update_velocity(delta)
	step_up(delta)
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	move_and_slide()
	step_down()
	rotate_character(desired_velocity, delta)

func update_velocity(delta) -> void:
	# Add the gravity.
	if is_grounded:
		target_speed = run_speed if Input.is_action_pressed("sprint") else walk_speed
		off_ground_time = 0
	else:
		off_ground_time += delta
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_grounded || off_ground_time < coyote_time):
		velocity.y = jump_strength
		
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var dir = (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y))
	dir.y = 0
	dir = dir.limit_length()
	
	if dir:
		var change = acceleration if is_grounded else acceleration * air_control
		var similar : float = clamp(dir.dot(desired_velocity), -1.0, 1.0)
		
		if similar < 0.5 and is_grounded:
			var multiplier : float = ((1.0 + similar) / 2.0) + 1.0
			change *= multiplier * change_direction_strength
		
		desired_velocity = desired_velocity.move_toward(dir * target_speed, delta * change)
	else:
		var change = deceleration if is_grounded else air_drag
		desired_velocity = desired_velocity.move_toward(Vector3.ZERO, delta * change)
		
	desired_velocity.y = velocity.y

func rotate_character(input_direction, delta):
	if rotate_towards_movement && visual && input_direction.length_squared() > 0.001:
		var target_vector = global_position.direction_to(global_position + input_direction)
		target_vector.y = 0
		if target_vector == Vector3.ZERO: return
		
		var target_basis = Basis.looking_at(target_vector)
		visual.basis = visual.basis.slerp(target_basis, delta * rotation_rate)

func step_up(delta) -> void:
	if !is_grounded: return
	
	var bottom = Vector3.DOWN * collider_height
	var motion_transform : Transform3D = global_transform
	var result = PhysicsTestMotionResult3D.new()
	var parameters = PhysicsTestMotionParameters3D.new()
	parameters.margin = collider_margin
	
	var distance = desired_velocity * delta
	parameters.from = motion_transform
	parameters.motion = distance
	
	# Nothing is obstructing us, so don't do anything
	if !PhysicsServer3D.body_test_motion(get_rid(), parameters, result):
		return
	
	# Move forward to the point of collision
	var remainder = result.get_remainder()
	motion_transform = motion_transform.translated(result.get_travel())
	
	# Keep moving up steps for the rest
	# of the desired horizontal move
	while remainder.length() >= EPSILON:
		# Lift up by the height of a default step
		var lift_up = step_height * Vector3.UP
		parameters.from = motion_transform
		parameters.motion = lift_up
		
		PhysicsServer3D.body_test_motion(get_rid(), parameters, result)
		motion_transform = motion_transform.translated(result.get_travel())
		var lift_distance = result.get_travel().length()
		
		
		# Now attempt to move forward the remaining distance
		parameters.from = motion_transform
		parameters.motion = remainder
		
		PhysicsServer3D.body_test_motion(get_rid(), parameters, result)
		motion_transform = motion_transform.translated(result.get_travel())
		
		# If we didn't move forward even after lifting, we're at a wall
		if abs(remainder.length() - result.get_remainder().length()) <= EPSILON:
			break
			
		# Update remainder
		remainder = result.get_remainder()
			
		# Place us back down again
		parameters.from = motion_transform
		parameters.motion = Vector3.DOWN * lift_distance
		
		# If nothing is found when shooting back down, don't do anything
		if !PhysicsServer3D.body_test_motion(get_rid(), parameters, result):
			break
			
		motion_transform = motion_transform.translated(result.get_travel())

		# Move player to match the step height we just found
		global_position.y = motion_transform.origin.y
	
func step_down() -> void:
	if !was_grounded || velocity.y >= 0: return
	
	var result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	
	params.from = global_transform
	params.motion = Vector3.DOWN * step_height
	params.margin = collider_margin
	
	if !PhysicsServer3D.body_test_motion(get_rid(), params, result):
		return
		
	global_transform = global_transform.translated(result.get_travel())
	apply_floor_snap()
