extends CharacterBody2D

@export var tile_size := 16
@export var move_speed := 128

var is_moving := false
var target_position := Vector2.ZERO
var move_input := Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	global_position = global_position.snapped(Vector2(tile_size, tile_size))
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		move_to_target(delta)
	else:
		update_input()
		if move_input != Vector2.ZERO:
			var next_pos = global_position + move_input * tile_size
			if can_move_to(next_pos):
				target_position = next_pos.snapped(Vector2(tile_size, tile_size))
				is_moving = true

func update_input():
	move_input = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		move_input.x += 1
	if Input.is_action_pressed("ui_left"):
		move_input.x -= 1
	if Input.is_action_pressed("ui_down"):
		move_input.y += 1
	if Input.is_action_pressed("ui_up"):
		move_input.y -= 1
	move_input = move_input.normalized()

func move_to_target(delta):
	var direction = (target_position - global_position).normalized()
	var distance = move_speed * delta

	if global_position.distance_to(target_position) <= distance:
		global_position = target_position
		is_moving = false
	else:
		velocity = direction * move_speed
		move_and_slide()
