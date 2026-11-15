extends CharacterBody2D

@onready var animated_sprite_1: AnimatedSprite2D = $AnimatedSprite1
@onready var animated_sprite_2: AnimatedSprite2D = $AnimatedSprite2
@onready var animated_sprite_3: AnimatedSprite2D = $AnimatedSprite3
@onready var animated_sprite_4: AnimatedSprite2D = $AnimatedSprite4
@onready var animated_sprite_5: AnimatedSprite2D = $AnimatedSprite5

@export var health := 9
@export var flip := false
@export var enemy_type: EnemyType

var sound := 0
enum EnemyType { ONE, TWO, THREE, FOUR, FIVE }

func _ready() -> void:
	if flip:
		animated_sprite_1.flip_h = true
		animated_sprite_2.flip_h = true
		animated_sprite_3.flip_h = true
		animated_sprite_4.flip_h = true
		animated_sprite_5.flip_h = true
	else:
		animated_sprite_1.flip_h = false
		animated_sprite_2.flip_h = false
		animated_sprite_3.flip_h = false
		animated_sprite_4.flip_h = false
		animated_sprite_5.flip_h = false
	
	if enemy_type == EnemyType.ONE:
		animated_sprite_1.show()
		animated_sprite_2.hide()
		animated_sprite_3.hide()
		animated_sprite_4.hide()
		animated_sprite_5.hide()
	elif enemy_type == EnemyType.TWO:
		animated_sprite_1.hide()
		animated_sprite_2.show()
		animated_sprite_3.hide()
		animated_sprite_4.hide()
		animated_sprite_5.hide()
	elif enemy_type == EnemyType.THREE:
		animated_sprite_1.hide()
		animated_sprite_2.hide()
		animated_sprite_3.show()
		animated_sprite_4.hide()
		animated_sprite_5.hide()
	elif enemy_type == EnemyType.FOUR:
		animated_sprite_1.hide()
		animated_sprite_2.hide()
		animated_sprite_3.hide()
		animated_sprite_4.show()
		animated_sprite_5.hide()
	elif enemy_type == EnemyType.FIVE:
		animated_sprite_1.hide()
		animated_sprite_2.hide()
		animated_sprite_3.hide()
		animated_sprite_4.hide()
		animated_sprite_5.show()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if health <= 0:
		queue_free()
	
	
	sound += 1
	print(sound)
	if sound == 1024:
		sound = 0
		Raycast.get_node("EchoLayer/EchoManager").max_distance == 32.0
		Raycast.get_node("EchoLayer/EchoManager").max_bounces == 2
		Raycast.get_node("EchoLayer/EchoManager").emit(global_position, self)

	move_and_slide()

func damage(damage: int):
	health -= damage
	Raycast.get_node("EchoLayer/EchoManager").max_distance == 48.0
	Raycast.get_node("EchoLayer/EchoManager").max_bounces == damage
	Raycast.get_node("EchoLayer/EchoManager").emit(global_position, self)
