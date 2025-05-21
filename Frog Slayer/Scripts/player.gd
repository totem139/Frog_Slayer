extends CharacterBody2D

@onready var animation: AnimationPlayer = $Animation
@onready var hitbox_collider: CollisionShape2D = $PlayerHitbox/HitboxCollider
@onready var sword_collider: CollisionShape2D = $DamageZone/SwordCollider
@onready var audio: AudioStreamPlayer2D = $Audio
@onready var run_audio: AudioStreamPlayer2D = $RunAudio
@onready var dash_audio: AudioStreamPlayer2D = $DashAudio


@export_category("Health Variable")
@export var health = 1000.0
var health_max = 100.0
var health_min = 0.0
var can_take_damage: bool
var dead: bool

@export_category("Move Variable")
@export var move_speed = 160.0
@export var deceleration = 0.1
@export var gravity = 500.0
var movement = Vector2()
var is_running: bool

@export_category("Jump Variable")
@export var jump_speed = 170.0
@export var acceleration = 290.0
@export var jump_amount = 2

@export_category("Dash Variable")
@export var dash_speed = 300.0
@export var facing_right = true
@export var dash_gravity = 0
@export var dash_number = 1
var dash_key_pressed = 0
var is_dashing = false
var dash_timer = Timer
var dash_sound = false

@export_category("Sword Variable")
@export var is_attacking: bool = false
@onready var damage_zone: Area2D = $DamageZone
var attack_type : String
var current_attack : bool
var weapon_equip: bool
@export var current_damage_to_deal= 20


#STRATER PROCESS
func _ready() -> void:
	Global.playerDamageZone = $DamageZone
	$DamageZone/SwordCollider.disabled = true
	Global.playerbody = self
	current_attack = false
	dead = false
	can_take_damage = true
	Global.playerAlive = true
	is_running = false
	randomize()

#GAME PROCESS
func _physics_process(delta: float) -> void:
	var weapon_equip= Global.playerWeaponEquip
	Global.playerDamageZone = damage_zone
	
	if !dead:
		if is_dashing == false:
			#ADD GRAVITY
			velocity.y += gravity * delta
		if is_dashing == true:
			velocity.y = dash_gravity
		
		if weapon_equip and !current_attack:
			if Input.is_action_just_pressed("sword"):
				current_attack = true
			
		check_hitbox()
	
	horizontal_movement()
	set_animations()
	set_audio()
	flip()
	jump_logic()
	set_damage()
	
	move_and_slide()
	restart()

#INPUT
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("sword"):
		is_attacking = true
		attack()

#MOVEMENT
func horizontal_movement():
	if is_dashing == false and !is_attacking:
		movement = Input.get_axis("left","right")
		
		if movement:
			velocity.x = movement * move_speed
			
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed * deceleration)
		
		if Input.is_action_just_pressed("dash") and dash_key_pressed == 0 and dash_number >= 1:
				dash_number -= 1
				dash_key_pressed = 1
				dash()

#ANIMATIONS
func set_animations():
	$Animation.speed_scale = 1.0
	if health > 0:
		if not is_attacking:
			if velocity.x != 0:
				$Animation.play("run")
				is_running = true
			if velocity.x == 0:
				$Animation.play("idle")
			if velocity.y < 0:
				$Animation.play("jump")
			if velocity.y > 40:
				$Animation.play("fall")
			if is_dashing == true:
				$Animation.play("dash")
		if is_attacking:
			$Animation.play("attack")
	if health <= 0:
		$Animation.play("dead")


func set_audio():
	if is_on_floor():
		if abs(velocity.x) > 0.1 and !is_attacking and !is_dashing:
			if not $RunAudio.playing:
				$RunAudio.play()
				$RunAudio.pitch_scale = randf_range(0.9, 1.1)
		elif $RunAudio.playing:
			$RunAudio.stop()
	elif $RunAudio.playing:
		$RunAudio.stop()
		
	if is_dashing:
		if not $DashAudio.playing:
			$DashAudio.play()
			dash_sound = true
		else:
			dash_sound = false

#FLIP SCALE STYLE
func flip():
	if velocity.x > 0.0:
		facing_right = true
		scale.x = scale.y * 1
	elif velocity.x < 0.0:
		facing_right = false
		scale.x = scale.y * -1

#JUMP
func jump_logic():
	if !dead:
		if is_on_floor():
			dash_number = 1
			jump_amount = 2
			if Input.is_action_just_pressed("jump"):
				jump_amount -= 1
				velocity.y -= lerp(jump_speed, acceleration, 0.7)
		if not is_on_floor():
			if jump_amount > 0:
				if Input.is_action_just_pressed("jump"):
					jump_amount -= 1
					velocity.y -= lerp(jump_speed, acceleration, 0.1)
					
				if Input.is_action_just_released("jump"):
					velocity.y -= lerp(jump_speed, acceleration, 0.2)
					velocity.y *= 0.3
		else: 
			return

#DASH
func dash():
	if dash_key_pressed == 1:
		is_dashing = true
	else:
		is_dashing = false
		
	if facing_right == true:
		velocity.x = dash_speed
		dash_started()
	if facing_right == false:
		velocity.x = -dash_speed
		dash_started()
	if is_dashing:
		hitbox_collider.disabled = true
		await get_tree().create_timer(0.3).timeout
		hitbox_collider.disabled = false

#DASH TIME
func dash_started():
	if !dead:
		if is_dashing == true:
			dash_key_pressed = 1
			await get_tree().create_timer(0.3).timeout
			is_dashing = false
			dash_key_pressed = 0
			
		else:
			return

#RESET THINGS
func reset_states():
	is_attacking = false


func attack():
	if is_attacking:
		if is_on_floor():
			velocity.x = 0
		if !is_on_floor():
			velocity.y *= 0.5
			velocity.x *= 0.25

#SET DAMAGE
func set_damage():
	Global.playerDamageAmount = current_damage_to_deal

#CHECK HITBOX FOR ENEMY
func check_hitbox():
	var hitbox_areas = $PlayerHitbox.get_overlapping_areas()
	var damage: int
	if hitbox_areas:
		var hitbox = hitbox_areas.front()
		if hitbox.get_parent() is FrogEnemy:
			damage = Global.frogDamageAmount
		
	if can_take_damage:
		take_damage(damage)

#TAKE DAMAGE
func take_damage(damage):
	if damage != 0:
		if health > 0:
			health -= damage
			print("plyaer health is:", health)
			if health <= 0:
				health = 0
				dead = true
				Global.playerAlive = false
				handle_death_animation()
			take_damage_cooldown(1.0)

#INVISIBILITY AFTER DAMAGE
func take_damage_cooldown(wait_time):
	can_take_damage= false
	await get_tree().create_timer(0.5).timeout
	can_take_damage = true

#DEATH ANİMATİON WİTH CAMERA
func handle_death_animation():
	$CollisionShape2D.position.y = 5
	
	print("dead")
	await get_tree().create_timer(0.5).timeout
	$Camera2D.zoom.x = 5
	$Camera2D.zoom.y = 5
	await get_tree().create_timer(3.5).timeout
	get_tree().reload_current_scene()

#RANDOM PICTH SCALE FOR SWORD SOUND
func audio_random_pitch():
	var random_pitch = randf_range(0.9, 1.2)
	audio.pitch_scale = random_pitch
	audio.play()

#FOR RESTART
func restart():
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
