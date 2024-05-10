class_name CameraOrbit3D
extends Node3D

@export_category("Mouse Settings")
@export var mouse_sensitivity : Vector2 = Vector2(3.0, 3.0)

@export_category("Orbit Settings")
@export var pitch_limit : Vector2 = Vector2(-90, 90)
@export var distance : float = 3.0
@export var camera_collision_radius : float = 0.4
@export var lateral_offset : float = 0.0
@export var collision_avoid_speed : float = 10.0

@onready var pivot : Node3D = get_parent()
var mouse_input : Vector2
var collider : CollisionShape3D
var target_position : Vector3
var desired_position : Vector3
var is_avoiding : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	position = Vector3(lateral_offset, 0, distance)
	target_position = position
	desired_position = position
	
	var sphere = SphereShape3D.new()
	sphere.radius = camera_collision_radius
	collider = CollisionShape3D.new()
	collider.shape = sphere

func _input(event):
	if event is InputEventMouseMotion:
		pivot.rotation.x -= event.relative.y * mouse_sensitivity.y * 0.001
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(pitch_limit.x), deg_to_rad(pitch_limit.y))
		pivot.rotation.y -= event.relative.x * mouse_sensitivity.x * 0.001
		mouse_input = event.relative
		
func _process(delta):
	position = position.lerp(target_position, delta * collision_avoid_speed)
		
func _physics_process(delta):
	var space_state = get_world_3d().direct_space_state
	
	if !is_avoiding:
		target_position.z = distance
	
		var shape_cast = PhysicsShapeQueryParameters3D.new()
		shape_cast.collide_with_areas = false
		shape_cast.collide_with_bodies = true
		shape_cast.shape = SphereShape3D.new()
		shape_cast.shape.radius = camera_collision_radius
		shape_cast.transform.origin = global_position
		shape_cast.exclude = [$"../.."]

		if space_state.intersect_shape(shape_cast): is_avoiding = true

	if is_avoiding:
		var line_cast = PhysicsRayQueryParameters3D.create(pivot.global_position, to_global(desired_position))
		line_cast.exclude = [$"../.."]
		
		var hit = space_state.intersect_ray(line_cast)
		
		target_position.z = to_local(hit.position).z - camera_collision_radius if hit else distance
		is_avoiding = !hit.is_empty()
