extends KinematicBody

const MAX_SPEED = 10
const JUMP_SPEED = 7
const ACCELERATION = 20
const DECELERATION = 40
const MAX_SLOPE_ANGLE = 30

onready var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity: Vector3
var face_dir: Vector3
var move_dir: Vector3
var is_moving: float
var time: float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera.set_as_toplevel(true)
	face_dir = Vector3(0, 0, 1)

func move(delta):
	move_dir = Vector3()
	move_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_dir.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	is_moving = Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") \
		or Input.is_action_pressed("move_backward") or Input.is_action_pressed("move_forward")
	
	# Get the camera's transform basis, but remove the X rotation such
	# that the Y axis is up and Z is horizontal.
	var cam_basis = $Camera.global_transform.basis
	var basis = cam_basis.rotated(cam_basis.x, -cam_basis.get_euler().x)
	move_dir = basis.xform(move_dir)
	
	# Limit the input to a length of 1. length_squared is faster to check.
	if move_dir.length_squared() > 1:
		move_dir /= move_dir.length()
	
	# Apply gravity.
	velocity.y += delta * gravity * 2
	#velocity = velocity.linear_interpolate(Vector3.UP, delta * gravity)
	
	# Using only the horizontal velocity, interpolate towards the input.
	var hvel = velocity
	hvel.y = 0

	var target = move_dir * MAX_SPEED
	var acceleration
	if move_dir.dot(hvel) > 0:
		acceleration = ACCELERATION
	else:
		acceleration = DECELERATION
	
	hvel = hvel.linear_interpolate(target, acceleration * delta)
	
	# Assign hvel's values back to velocity, and then move.
	velocity.x = hvel.x
	velocity.z = hvel.z
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# Jumping code. is_on_floor() must come after move_and_slide().
	if is_on_floor() and Input.is_action_pressed("move_jump"):
		velocity.y = JUMP_SPEED * 2
		#velocity = velocity.linear_interpolate(Vector3.UP * JUMP_SPEED * 5, ACCELERATION * delta)

func face(delta):
	if is_moving:
		face_dir = move_dir
		var a = Quat(transform.basis)
		var b = Quat(Vector3.UP, face_dir.angle_to(Vector3.BACK) * sign(face_dir.x))
		transform.basis = Basis(a.slerp(b, 0.2))

func _physics_process(delta):
	time += delta
	move(delta)
	face(delta)
