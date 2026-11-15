extends CharacterBody2D

# 70% comments 30% ai code
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_2d: Area2D = $AttackArea2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var wall_ray_cast_2d: RayCast2D = $WallRayCast2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

@export var speed := 150.0
@export var jump_velocity := -220.0

var _was_on_floor := false
var _climbing := false
var _in_area := true
var damage := 3.0

func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		if wall_ray_cast_2d.is_colliding() and not is_on_floor():
			if Input.is_action_pressed("climb"):
				var direction_y := Input.get_axis("up", "down")
				
				if velocity.y == 0:
					animated_sprite_2d.pause()
				else:
					animated_sprite_2d.play("climb")
				
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
		if not animated_sprite_2d.is_playing():
			animated_sprite_2d.play("idle")
		velocity.x = move_toward(velocity.x, 0, speed)
	if direction < 0:
		animated_sprite_2d.flip_h = true
		attack_area_2d.position.x = -6.0
		wall_ray_cast_2d.target_position.x = -8
		cpu_particles_2d.position.x = -6.0
	elif direction > 0:
		animated_sprite_2d.flip_h = false
		attack_area_2d.position.x = 6.0
		wall_ray_cast_2d.target_position.x = 8
		cpu_particles_2d.position.x = 6.0

	_was_on_floor = is_on_floor()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("blip") and cooldown_timer.is_stopped():
		Raycast.get_node("EchoLayer/EchoManager").emit(global_position, self)
		$AudioStreamPlayer2D.play()
		cooldown_timer.start()
	if Input.is_action_just_pressed("attack") and attack_cooldown_timer.is_stopped():
		animated_sprite_2d.play("bite")
		if _in_area:
			for area in attack_area_2d.get_overlapping_areas():
				if area.is_in_group("enemy"):
					area.damage(damage)
					cpu_particles_2d.emitting = true
			
			


func _on_attack_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_in_area = true


func _on_attack_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		_in_area = false
