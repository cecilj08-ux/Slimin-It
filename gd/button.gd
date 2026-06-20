extends StaticBody2D

@onready var sprite := $Sprite2D
@export var one_shot := false
@export var activates: Node2D
var pressed := false
var total_collisions := 0

func _ready() -> void: if activates and activates is Door: activates.has_activator = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if ((body is Player or body is Enemy) and body.new_scale >= scale) or (body is Crate and body.scale >= scale):
		total_collisions += 1
		pressed = true
		#set_collision_layer_value(1, false)
		#set_collision_layer_value(6, false)
		sprite.frame = 1
		if activates is Door: activates.open()
		if activates is Gate: activates.opening = true
		if one_shot:
			await get_tree().create_timer(1.5).timeout
			queue_free()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if (body is CharacterBody2D or body is Crate) and pressed and not one_shot:
		total_collisions -= 1
		if total_collisions > 0: return
		pressed = false
		#set_collision_layer_value(1, true)
		#set_collision_layer_value(6, true)
		if not one_shot:
			sprite.frame = 0
			if activates is Door: activates.close()
			if activates is Gate: activates.opening = false
