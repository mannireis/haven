extends CharacterBody2D

# 70% comments 30% ai code
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_2d: Area2D = $AttackArea2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var wall_ray_cast_2d: RayCast2D = $WallRayCast2D


@export var speed := 150.0
@export var jump_velocity := -220.0

var was_on_floor := false
var climbing := false

func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		if wall_ray_cast_2d.is_colliding() and not is_on_floor():
			if Input.is_action_pressed("climb"):
				var direction_y := Input.get_axis("up", "down")

				velocity.y = direction_y * 50
				climbing = true
			else:
				velocity.y += 3
				climbing = false
		if was_on_floor and velocity.y >= 0:
			coyote_timer.start()

	if Input.is_action_just_pressed("jump") and (is_on_floor() or not coyote_timer.is_stopped() or climbing):
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
		animated_sprite_2d.flip_h = true
		attack_area_2d.position.x = -10.0
		wall_ray_cast_2d.target_position.x = -8
	elif direction > 0:
		animated_sprite_2d.flip_h = false
		attack_area_2d.position.x = 10.0
		wall_ray_cast_2d.target_position.x = 8

	was_on_floor = is_on_floor()
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("blip") and cooldown_timer.is_stopped():
		Raycast.get_node("EchoLayer/EchoManager").emit(global_position, self)
		$AudioStreamPlayer2D.play()
		cooldown_timer.start()
