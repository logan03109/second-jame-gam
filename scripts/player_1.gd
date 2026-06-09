extends CharacterBody2D

@export var left_action := "p1_left"
@export var right_action := "p1_right"
@export var jump_action := "p1_jump"
@export var down_action := "p1_down"
@export var dash_action := "p1_dash"
@export var device_id := 0

@onready var anim = $AnimatedSprite2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const DOWN_VELOCITY = -400.0
const INIT_ACCEL = 4500.0
const FRICTION = 2500.0
const AIR_RESISTANCE = 500.0
const DEATH_Y  := 300.0
const DASH_SPEED := 400.0
const DASH_DURATION := 0.15
const DASH_COOLDOWN := 0.5

var jump_count:int = 2
var time_passed:float = 0.0
var was_on_floor := false
var is_dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := 1.0

func _on_landed():
	pass

func _die():
	visible = false
	set_physics_process(false)
	get_tree().call_group("main", "_on_player_died", self)

func _physics_process(delta):

	if global_position.y > DEATH_Y:
		_die()
		return

	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		jump_count = 2

	# -------------------------
	# KEYBOARD INPUT (existing)
	# -------------------------
	var kb_left := Input.is_action_pressed(left_action)
	var kb_right := Input.is_action_pressed(right_action)
	var kb_jump := Input.is_action_just_pressed(jump_action)
	var kb_down := Input.is_action_just_pressed(down_action)
	var kb_dash := Input.is_action_just_pressed(dash_action)

	# -------------------------
	# CONTROLLER INPUT
	# -------------------------
	var axis_x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)

	var pad_left := axis_x < -0.2
	var pad_right := axis_x > 0.2

	var pad_jump := Input.is_joy_button_pressed(device_id, JOY_BUTTON_A) # X
	var pad_dash := Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER) # R1
	var pad_down := Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_SHOULDER) # L1

	# -------------------------
	# MERGED INPUTS
	# -------------------------
	var left := kb_left or pad_left
	var right := kb_right or pad_right
	var jump := kb_jump or pad_jump
	var down := kb_down or pad_down
	var dash := kb_dash or pad_dash

	# -------------------------
	# DASH
	# -------------------------
	if dash and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN

		var dir := 0
		if left: dir -= 1
		if right: dir += 1

		if axis_x != 0:
			dir = sign(axis_x)
	
		if dir != 0:
			dash_direction = dir  
		else:
			dash_direction

	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0

		if dash_timer <= 0.0:
			is_dashing = false

		move_and_slide()
		return

	# -------------------------
	# JUMP
	# -------------------------
	if jump and jump_count > 0:
		jump_count -= 1
		velocity.y = JUMP_VELOCITY

	# -------------------------
	# DOWN
	# -------------------------
	if down and not is_on_floor():
		velocity.y -= DOWN_VELOCITY

	# -------------------------
	# MOVEMENT
	# -------------------------
	var direction := 0

	if left:
		direction -= 1
	if right:
		direction += 1

	if abs(axis_x) > 0.2:
		direction = sign(axis_x)

	if direction != 0:
		if not is_on_floor():
			velocity.x = move_toward(velocity.x, direction * SPEED, INIT_ACCEL * delta)
			anim.play("jump")
		else:
			velocity.x = move_toward(velocity.x, direction * SPEED, INIT_ACCEL * delta)
			anim.play("run")

		anim.flip_h = direction < 0

	else:
		if not is_on_floor():
			velocity.x = move_toward(velocity.x, 0, AIR_RESISTANCE * delta)
			anim.play("jump")
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			anim.play("idle")

	move_and_slide()
