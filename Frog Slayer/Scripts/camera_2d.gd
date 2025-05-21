extends Camera2D

@onready var ground: TileMap = $"../TileMap"
@onready var player: CharacterBody2D = $"../Player"

@export var horizontal_dead_zone = 30
@export var vertica_dead_zone = 30
@export var follow_speed = 160
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func update_camera_position():
	if not player:
		return
	
	var player_pos = player.global_position
	var camera_pos = global_position
	var viewport_size = get_viewport_rect().size /zoom
