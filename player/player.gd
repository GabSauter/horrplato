extends CharacterBody2D
class_name Player

@export var moveData = preload("res://player/DefaultPlayerMovementData.tres") as PlayerMovementData

@onready var animatedSprite = $AnimatedSprite2D
@onready var ladderCheck = $LadderCheck
@onready var jumpBufferTimer = $JumpBufferTimer
@onready var coyoteJumpTimer = $CoyoteJumpTimer
@onready var remoteTransform2D = $RemoteTransform2D
@onready var wall_jump_timer = $WallJumpTimer

enum { MOVE, CLIMB }

var state = MOVE
var double_jump = 1
var just_wall_jump = false
var buffered_jump = false
var coyote_jump = false

var was_wall_normal = Vector2.ZERO

func _ready():
	animatedSprite.frames = load("res://player/PlayerGreenSkin.tres")

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = Input.get_axis("ui_left", "ui_right")
	input.y = Input.get_axis("ui_up", "ui_down")
	
	match state:
		MOVE: move_state(input, delta)
		CLIMB: climb_state(input)

func move_state(input, delta):
	if is_on_ladder() and Input.is_action_just_pressed("ui_up"):
		state = CLIMB
	
	apply_gravity(delta)
	if horizontal_move(input):
		if is_on_floor():
			apply_acceleration(input.x, delta)
		else:
			apply_air_acceleration(input.x, delta)
		animatedSprite.animation = "Run"
		animatedSprite.flip_h = input.x > 0
	else:
		apply_friction(delta)
		apply_air_resistence(delta, input.x)
		animatedSprite.animation = "Idle"
	
	if is_on_floor():
		reset_double_jump()
	else:
		animatedSprite.animation = "Jump"
		handle_wall_jump()
	
	if can_jump():
		input_jump()
	else:
		input_jump_released()
		input_double_jump()
		buffer_jump()
		fast_fall(delta)
	
	var was_in_air = not is_on_floor()
	var was_on_floor = not was_in_air
	var was_on_wall = is_on_wall_only()
	if was_on_wall:
		was_wall_normal = get_wall_normal()
	move_and_slide()
	
	var just_landed = was_in_air and is_on_floor()
	if just_landed:
		animatedSprite.animation = "Run"
		animatedSprite.frame = 1
	
	var just_left_ground = not is_on_floor() and was_on_floor
	if just_left_ground and velocity.y >= 0:
		coyote_jump = true
		coyoteJumpTimer.start()
	just_wall_jump = false
	
	var just_left_wall = was_on_wall and not is_on_wall()
	if just_left_wall:
		wall_jump_timer.start()
	

func fast_fall(delta):
	if velocity.y > 0:
			velocity.y += moveData.ADITIONAL_FALL_GRAVITY * delta

func buffer_jump():
	if Input.is_action_just_pressed("ui_accept"):
			buffered_jump = true
			jumpBufferTimer.start()

func input_double_jump():
	if double_jump > 0 and Input.is_action_just_pressed("ui_up") and not just_wall_jump:
			SoundPlayer.play_sound(SoundPlayer.JUMP)
			velocity.y = moveData.JUMP_FORCE * 0.8
			double_jump -= 1

func input_jump_released():
	if Input.is_action_just_released("ui_accept") and velocity.y < moveData.JUMP_RELEASE_FORCE:
			velocity.y = moveData.JUMP_RELEASE_FORCE

func horizontal_move(input):
	return input.x != 0

func can_jump() -> bool:
	return is_on_floor() or coyote_jump

func input_jump():
	if Input.is_action_just_pressed("ui_up") or buffered_jump:
			SoundPlayer.play_sound(SoundPlayer.JUMP)
			velocity.y = moveData.JUMP_FORCE
			buffered_jump = false

func reset_double_jump():
	double_jump = moveData.MAX_DOUBLE_JUMPS

func climb_state(input):
	if not is_on_ladder(): state = MOVE
	if input.length() != 0: 
		animatedSprite.animation = "Run"
	else:
		animatedSprite.animation = "Idle"
	velocity = input * moveData.CLIMB_SPEED
	move_and_slide()

func player_die():
	SoundPlayer.play_sound(SoundPlayer.HIT)
	queue_free()
	Events.emit_signal("player_died")

func handle_wall_jump():
	if not is_on_wall_only() and wall_jump_timer.time_left <= 0.0: return
	var wall_normal = get_wall_normal()
	if wall_jump_timer.time_left > 0.0:
		wall_normal = was_wall_normal
	if Input.is_action_just_pressed("ui_up"):
		velocity.x = wall_normal.x * (moveData.MAX_SPEED)
		velocity.y = moveData.JUMP_FORCE
		just_wall_jump = true

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += moveData.GRAVITY * delta
		velocity.y = min(velocity.y, 300)

func apply_friction(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, moveData.FRICTION * delta)

func apply_air_resistence(delta, direction):
	if direction == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, moveData.AIR_RESISTENCE * delta)

func apply_acceleration(direction: int, delta):
	velocity.x = move_toward(velocity.x, moveData.MAX_SPEED * direction, moveData.ACCELERATION * delta)

func apply_air_acceleration(direction: int, delta):
	velocity.x = move_toward(velocity.x, moveData.MAX_SPEED * direction, moveData.AIR_ACCELERATION * delta)

func power_up():
	moveData = load("res://FastPlayerMovementData.tres")

func is_on_ladder():
	if not ladderCheck.is_colliding(): return false
	var collider = ladderCheck.get_collider()
	if not collider is Ladder: return false
	return true

func _on_jump_buffer_timer_timeout():
	buffered_jump = false

func _on_coyote_jump_timer_timeout():
	coyote_jump = false

func connect_camera(camera):
	var camera_path = camera.get_path()
	remoteTransform2D.remote_path = camera_path
