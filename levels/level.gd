extends Node2D

const PlayerScene = preload("res://player/player.tscn")

@onready var camera: = $Camera2D
@onready var player: = $Player
@onready var timer: = $Timer

var player_spawn_location = Vector2.ZERO

func _ready():
	RenderingServer.set_default_clear_color(Color.LIGHT_BLUE)
	player.connect_camera(camera)
	player_spawn_location = player.position
	Events.player_died.connect(_on_player_died)
	Events.hit_checkpoint.connect(_on_hit_checkpoint)

func _on_player_died():
	timer.start(1.0)
	await timer.timeout
	var player = PlayerScene.instantiate()
	player.position = player_spawn_location 
	add_child(player)
	player.connect_camera(camera)

func _on_hit_checkpoint(checkpoint_position):
	player_spawn_location = checkpoint_position
	
