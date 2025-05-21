extends CharacterBody2D
class_name  Target


@onready var hitbox: Area2D = $HitboxArea

var health = 100
var is_alive = true

func _ready():
	hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))


func _on_hitbox_area_entered(area):
	if area.name == "DamageZone": # Player'ın hasar bölgesi
		take_damage(Global.playerDamageAmount)
	
func take_damage(amount):
	if is_alive:
		health -= amount
		print("Target health:", health)
		if health <= 0:
			health = 0
			is_alive = false
			die()

func die():
	print("Target is dead")
	queue_free()
