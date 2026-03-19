extends CharacterBody3D

@onready var COLLIDER: CollisionShape3D = $collider
@onready var CAM_PIVOT: Node3D = $camPivot
@onready var CAMERA: Camera3D = $camPivot/camera

@export_group("Camera Stuff")
@export var mouse_sensitivity: float = 0.002
@export var camera_x_rotation: float = 0.0

@export_group("Movement Stuff")
@export_subgroup("Booleans")
@export var IS_DASHING : bool = false
@export var GROUNDED : bool = false
@export var WALL_COLLIED : bool = false
@export var IS_MOVING : bool = false
@export var IS_JUMPING : bool = false
@export var CAN_WALL_JUMP : bool = false

@export_subgroup("General Variables (gravity, friction, etc)")
@export var FRICTION: float = 5.0
@export var FRICTION_DELAY: float = 2.5
@export var GRAVITY: float = 2.5

@export_subgroup("Speed Alterations")
@export var SPEED : float = 3.0
@export var MAX_SPEED: float = 5.0
@export var ACCELERATION: float = 5.0
@export var DASH_SPEED: float = 15.0
@export var JUMP_HEIGHT: float = 5

@export_subgroup("Wall Bullshit")
@export var REMAINING_WALL_JUMPS: int = 3
@export var WALL_JUMP_ANGLE: float = 0.0
@export_group("")


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var ui = $camPivot/camera/UI/Control
	ui.player = self


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, deg_to_rad(-80), deg_to_rad(80))
		CAM_PIVOT.rotation.x = camera_x_rotation

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta):
	GROUNDED = is_on_floor()

	# --- Gravity ---
	if not GROUNDED:
		velocity.y -= GRAVITY * delta * 10.0
	else:
		REMAINING_WALL_JUMPS = 3
		if velocity.y < 0:
			velocity.y = 0

	# --- Input ---
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var cam_basis = CAMERA.global_transform.basis

	var direction = (cam_basis.z * input_dir.y + cam_basis.x * input_dir.x)
	direction.y = 0
	direction = direction.normalized()

	IS_MOVING = direction.length() > 0

	if GROUNDED:
		if IS_MOVING:
			var target_velocity = direction * MAX_SPEED

			velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta * 8.0)
			velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta * 8.0)
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta * 4.0)
			velocity.z = move_toward(velocity.z, 0, FRICTION * delta * 4.0)
	else:
		pass


	if Input.is_action_just_pressed("jump"):
		if GROUNDED:
			velocity.y = JUMP_HEIGHT * 2.0
			IS_JUMPING = true
		elif CAN_WALL_JUMP and REMAINING_WALL_JUMPS > 0:
			var wall_normal = get_wall_collision_normal()
			velocity = wall_normal * MAX_SPEED
			velocity.y = JUMP_HEIGHT * 2.0
			REMAINING_WALL_JUMPS -= 1


	if Input.is_action_just_pressed("dash") and not IS_DASHING:
		start_dash(direction)

	WALL_COLLIED = is_on_wall()
	CAN_WALL_JUMP = WALL_COLLIED and not GROUNDED

	move_and_slide()


func start_dash(direction):
	if direction == Vector3.ZERO:
		return

	IS_DASHING = true
	velocity.x = direction.x * DASH_SPEED
	velocity.z = direction.z * DASH_SPEED

	await get_tree().create_timer(0.2).timeout
	IS_DASHING = false


func get_wall_collision_normal() -> Vector3:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_normal().y < 0.1:
			return collision.get_normal()
	return Vector3.ZERO
