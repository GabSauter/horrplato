@tool
extends Path2D

enum ANIMATION_TYPE { LOOP, BOUNCE }

@export var animation_type:ANIMATION_TYPE: set = set_animation_type
@export var speed:int: set = set_speed

@onready var animation_player = $AnimationPlayer

func _ready():
	play_updated_animation(animation_player)

func play_updated_animation(ap):
	match animation_type:
		ANIMATION_TYPE.LOOP: ap.play("MoveAlongPathLoop")
		ANIMATION_TYPE.BOUNCE:ap.play("MoveAlongPathBounce")

func set_speed(value):
	speed = value
	var ap = get_node("AnimationPlayer")
	if ap: ap.speed_scale = speed

func set_animation_type(value):
	animation_type = value
	var ap = find_child("AnimationPlayer")
	if ap: play_updated_animation(ap)
