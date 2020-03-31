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


# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera.set_as_toplevel(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	var direction = Vector3()
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")  
	
	# Get the camera's transform basis, but remove the X rotation such
	# that the Y axis is up and Z is horizontal.
	var cam_basis = $Camera.global_transform.basis
	var basis = cam_basis.rotated(cam_basis.x, -cam_basis.get_euler().x)
	direction = basis.xform(direction)
	
	# Limit the input to a length of 1. length_squared is faster to check.
	if direction.length_squared() > 1:
		direction /= direction.length()
	
	#if direction.length_squared() > 0:
		#rotation = rotation.linear_interpolate(Vector3(0, direction.angle_to(Vector3.BACK) * sign(direction.x), 0), delta * 10)
		#rotate_y(direction.angle_to(rotation))
	#rotation = Vector3(0, 2, 0)
	#print(Engine.get_frames_per_second())
	var a = Quat(transform.basis)
	var b = Quat(Vector3.UP, direction.angle_to(Vector3.BACK) * sign(direction.x))
	transform.basis = Basis(a.slerp(b, 0.5))
	
	
	# Apply gravity.
	velocity.y += delta * gravity * 2
	#velocity = velocity.linear_interpolate(Vector3.UP, delta * gravity)
	
	# Using only the horizontal velocity, interpolate towards the input.
	var hvel = velocity
	hvel.y = 0

	var target = direction * MAX_SPEED
	var acceleration
	if direction.dot(hvel) > 0:
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
