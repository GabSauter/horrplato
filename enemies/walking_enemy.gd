extends CharacterBody2D

@onready var animatedSprite = $AnimatedSprite2D
@onready var ledgeCheck = $LedgeCheck

var direction = Vector2.LEFT

func _physics_process(delta):
	var found_wall = is_on_wall()
	var found_ledge = not ledgeCheck.is_colliding()
	
	if found_wall or found_ledge:
		direction *= -1
		scale.x *= -1
	
	velocity = direction * 25
	
	move_and_slide()
