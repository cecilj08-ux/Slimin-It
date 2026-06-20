@abstract class_name Enemy extends CharacterBody2D

@onready var ani := $Sprite2D/AnimationPlayer
@onready var sprite := $Sprite2D

@export var speed := 80
@export var jump_power := 220
@export var fallspeed_cap := 600
@export var detection_range := 50

var target = null
var can_jump := true
var aggressive := false
var dead := false

func apply_gravity(delta: float) -> void:
	velocity += get_gravity() * delta
	if velocity.y > fallspeed_cap: velocity.y = fallspeed_cap

func _on_detection_body_entered(body: Node2D) -> void: if body is Player: target = body
func _on_detection_body_exited(body: Node2D) -> void: if body is Player: target = null
