class_name Gate extends StaticBody2D

var opening := false
var frozen_sprite := preload("res://resources/1bit slime platformer/gate_w.png")
@onready var collision_box := $collisionBox
@onready var sprite := $sprite
@onready var occluder_box := $occluderBox
@export var height := 1
@export var open_speed := 120
@export var close_speed := 120
@export var inverted := false
@export var frozen := false
@export_group("World selector specific")
@export var world: int
@export var stage: int
@export var secret_stage: bool

func _ready() -> void:
	if !frozen: sprite.texture = frozen_sprite
	sprite.region_rect.size.y = 8*height if not inverted else 8
	collision_box.shape.size.y = 8*height if not inverted else 8
	collision_box.position.y += 8*(height*0.5)-4
	if stage != 0:
		if secret_stage and stage in SaveManager.save_game.unlocked_secrets[world]: inverted = true
		elif stage in SaveManager.save_game.unlocked_stages[world]: inverted = true

func _physics_process(delta: float) -> void:
# Sprite Resizing
	if opening == not inverted: sprite.region_rect.size.y = move_toward(sprite.region_rect.size.y, 8, open_speed*delta)
	else: sprite.region_rect.size.y = move_toward(sprite.region_rect.size.y, height*8, close_speed*delta)
# Collision Resizing
	collision_box.shape.size.y = sprite.region_rect.size.y
	collision_box.position.y = sprite.region_rect.size.y/2
# Occluder Resizing
	occluder_box.occluder.polygon[2].y = collision_box.shape.size.y
	occluder_box.occluder.polygon[3].y = collision_box.shape.size.y
