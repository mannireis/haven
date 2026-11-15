extends CharacterBody2D

# 70% comments 30% ai code
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_2d: Area2D = $AttackArea2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var wall_ray_cast_2d: RayCast2D = $WallRayCast2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

@export var speed := 120.0
@export var jump_velocity := -220.0

var _was_on_floor := false
var _climbing := false
var _in_area := true
var damage := 3.0
var _was_in_air := false
var _landing := false
var _attacking := false

func _ready() -> void:
	add_to_group("player")
	Raycast.hide()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		if wall_ray_cast_2d.is_colliding() and not is_on_floor():
			if Input.is_action_pressed("climb"):
				var direction_y := Input.get_axis("up", "down")

				velocity.y = direction_y * 50
				_climbing = true
			else:
				animated_sprite_2d.pause()
				velocity.y += 3
				_climbing = false
		if _was_on_floor and velocity.y >= 0:
			coyote_timer.start()

	if Input.is_action_just_pressed("jump") and (is_on_floor() or not coyote_timer.is_stopped() or _climbing):
		velocity.y = jump_velocity
		coyote_timer.stop()
	if Input.is_action_just_released("jump"):
		velocity.y *= 0.8

	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	if direction < 0:
		attack_area_2d.position.x = -6.0
		wall_ray_cast_2d.target_position.x = -8
		cpu_particles_2d.position.x = -6.0
	elif direction > 0:
		attack_area_2d.position.x = 6.0
		wall_ray_cast_2d.target_position.x = 8
		cpu_particles_2d.position.x = 6.0
	
	
	_was_in_air = is_on_floor()
	_was_on_floor = is_on_floor()
	
	var fall_speed := velocity.y
	move_and_slide()
	
	if is_on_floor() and not _was_on_floor and fall_speed > 150.0:
		_landing = true
		animated_sprite_2d.play("land")

	_update_animation()


func _update_animation() -> void:
	if velocity.x != 0:
		animated_sprite_2d.flip_h = velocity.x < 0

	if _climbing:
		if velocity.y == 0:
			animated_sprite_2d.play("climb_pause")
		else:
			animated_sprite_2d.play("climb")
	elif _attacking:
		animated_sprite_2d.play("bite")
		await animated_sprite_2d.animation_finished
		_attacking = false
	elif not is_on_floor():
		animated_sprite_2d.play("fall")
	elif absf(velocity.x) > 1.0:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("blip") and cooldown_timer.is_stopped():
		Raycast.get_node("EchoLayer/EchoManager").max_distance == 900.0
		Raycast.get_node("EchoLayer/EchoManager").max_bounces == 3
		Raycast.get_node("EchoLayer/EchoManager").emit(global_position, self)
		$AudioStreamPlayer2D.play()
		cooldown_timer.start()
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer.is_stopped():
		_attacking = true
		if _in_area:
			for area in attack_area_2d.get_overlapping_areas():
				if area.get_parent().is_in_group("enemy"):
					area.get_parent().damage(damage)
					cpu_particles_2d.emitting = true


func _on_attack_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_in_area = true


func _on_attack_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_in_area = false
