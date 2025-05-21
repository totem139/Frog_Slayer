extends CharacterBody2D
class_name  FrogEnemy


@onready var hitbox: Area2D = $HitboxArea
@onready var vision_ray: RayCast2D = $VisionRay
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_zone: Area2D = $AttackZone
@onready var notice_zone: Area2D = $NoticeZone
@onready var frog_real: AudioStreamPlayer2D = $FrogReal


var player: CharacterBody2D

#PHYSİCS
var speed = 50.0
var gravity = 500.0
var dir: Vector2

#LIFE
var health = 40
var is_alive = true
var facing_right = true

#FIGHT
var can_take_damage: bool = true
var damage = Global.playerDamageAmount
var is_frog_chase: bool
var taking_damage = false
var can_attack = false
var attack_cooldown = 10.0
var player_in_notice_zone = false
var damage_to_deal = 10
var is_attacking = false

#KNOCKBACK
var knockback_force = Vector2.ZERO
var knockback_decay = 500.0  # ne kadar hızlı duracak


#CHASE
var is_roaming: bool
var detection_range = 150.0
var damage_timer = 0.0
var damage_duration = 0.5
var max_view_angle = 45.0
var forget_delay = 2.0
var forget_timer = 0.0

#GAME START
func _ready():
	Global.frogDamageZone = $AttackZone
	$AttackZone/CollisionShape2D.disabled = true
	hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
	notice_zone.connect("body_entered", Callable(self, "_on_notice_zone_body_entered"))
	attack_zone.connect("body_entered", Callable(self, "_on_attack_zone_body_entered"))
	is_frog_chase = true
	can_take_damage = true
	animation_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

#GAME ALONG
func _process(delta: float) -> void:
	if not $FrogReal.playing:
		if is_alive:
			$FrogReal.play()
		else:
			$FrogReal.stop()
	
	if is_instance_valid(Global.playerbody):
		player = Global.playerbody
		var distance_to_player = global_position.distance_to(player.global_position)

		if distance_to_player <= detection_range and can_see_player():
			is_frog_chase = true
			forget_timer = 0.0  # tekrar görünce sıfırla
		else:
			# Görüş dışında → saymaya başla
			if is_frog_chase:
				forget_timer += delta
				if forget_timer >= forget_delay:
					is_frog_chase = false
					forget_timer = 0.0
	move(delta)
	set_damage()
	handle_animations()

	
#MOVE
func move(delta):
	
	if is_frog_chase:
		player = Global.playerbody
		if is_instance_valid(player):
			var direction = player.global_position.x - global_position.x

			if abs(direction) > 5.0:  # çok yakınsa hareket etmesin
				velocity.x = sign(direction) * speed
			else:
				velocity.x = 0
	else:
		velocity.x = dir.x * speed  # devriye sırasında sadece x yönü

	# Yerçekimini sadece y eksenine uygula
	if !is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0  # yere basıyorsak y hızı sıfırlanır

	move_and_slide()
	flip()


#FLIP
func flip():
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y * 1 
	elif velocity.x < 0.0:
		facing_right = false
		scale.x = scale.y * -1

#DAMAGE CONTROL
func _on_hitbox_area_entered(area):
	if area.name == "DamageZone": # Player'ın hasar bölgesi
		take_damage(Global.playerDamageAmount)

#TAKE DAMAGE
func take_damage(damage):
	if is_alive and !taking_damage:
		health -= damage
		taking_damage = true
		
		#Knockback yönünü ayarla
		var direction = (global_position - player.global_position).normalized()
		knockback_force = direction * 200  # kuvveti isteğine göre ayarla
		
		$AnimationPlayer.play("damage")
		await get_tree().create_timer(0.4).timeout
		taking_damage = false
		print("Frog health:", health)
	if health <= 0:
		health = 0
		is_alive = false
		die()
	

#DIE
func die():
	$AttackZone/CollisionShape2D.call_deferred("set_disabled", true)
	$NoticeZone/CollisionShape2D.call_deferred("set_disabled", true)
	is_alive = false
	$AnimationPlayer.play("death")
	await get_tree().create_timer(0.8).timeout
	print("Frog is dead")
	call_deferred("queue_free") 
	

func _on_timer_timeout():
	$Timer.wait_time = choose([1.0, 1.5, 2.0])
	if !is_frog_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])

func choose(array):
	array.shuffle()
	return array.front()

func handle_animations():
	if is_alive and !taking_damage and !is_attacking:
		if velocity.x == 0:
			$AnimationPlayer.play("idle")
		if velocity.x != 0:
			$AnimationPlayer.play("walk")
	

func can_see_player() -> bool:
	if !is_instance_valid(player):
		return false

	var to_player = player.global_position - global_position
	
	# Görme açısı: sadece baktığı yönde ise görsün
	if (to_player.x > 0 and !facing_right) or (to_player.x < 0 and facing_right):
		return false  # oyuncu arkada, görme

	# RayCast yönünü dinamik olarak ayarla
	vision_ray.target_position = to_player.normalized() * detection_range
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		var collider = vision_ray.get_collider()
		# Eğer çarpılan şey player ise görüyordur
		if collider == player:
			return true
		else:
			return false  # arada duvar var
	else:
		return false  # bir şeyle çarpmadıysa göremiyor

	return true

func _on_attack_zone_body_entered(body):
	if body.name == "player" and is_alive and can_attack and player_in_notice_zone:
		if is_instance_valid(body) and body.has_method("take_damage"):
			is_attacking = true
			$AnimationPlayer.play("attack")
			can_attack = false
			await get_tree().create_timer(attack_cooldown).timeout
			can_attack = true
			is_attacking = false
		print("vurma alanına birisi girdi")

func set_damage():
	Global.frogDamageAmount = damage_to_deal

func _on_notice_zone_body_entered(body):
	if body.name == "player":
		player_in_notice_zone = true

func _on_notice_zone_body_exited(body):
	if body.name == "player":
		player_in_notice_zone = false


func deal_attack_damage():
	if is_alive and is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage_to_deal)
		print("frog vurdu")
		
func _on_animation_finished(animation_player):
	if animation_player == "attack":
		is_attacking = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
