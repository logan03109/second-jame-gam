extends CharacterBody2D

@export var left_action := "p1_left"
@export var right_action := "p1_right"
@export var jump_action := "p1_jump"
@export var down_action := "p1_down"
@export var dash_action := "p1_dash"
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
	
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		return
	if is_on_floor():
		jump_count = 2
	
	if Input.is_action_just_pressed(jump_action) and jump_count > 0:
		jump_count -= 1 
		velocity.y = JUMP_VELOCITY	
	
	if Input.is_action_just_pressed(down_action) and not is_on_floor():
		velocity.y = velocity.y - DOWN_VELOCITY
	
	if Input.is_action_just_pressed(dash_action) and dash_cooldown_timer <= 0.0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		var dir := Input.get_axis(left_action, right_action)
		dash_direction = dir if dir != 0.0 else dash_direction

	var direction := Input.get_axis(left_action, right_action)

	if direction and not is_on_floor():
		velocity.x = move_toward(velocity.x, direction * SPEED, INIT_ACCEL * delta)
		anim.play("run")
		anim.flip_h = direction < 0
	elif direction:
		velocity.x += 50
		velocity.x = move_toward(velocity.x, direction * SPEED, INIT_ACCEL * delta)
		anim.play("run")
		anim.flip_h = direction < 0
	elif not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, AIR_RESISTANCE * delta)
		anim.play("idle")  # or "jump" if you have one
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		anim.play("idle")

	move_and_slide()
