extends Sprite2D

var reading := false

@onready var text_box: PanelContainer = $textBox
@onready var text: Label = $textBox/text

@export_multiline var writing: String
@export var reading_time := 4
@export var collapsing_time := 1

@export_group("Time Trial")
@export var time_trial_display: bool
@export var time_trial_world: int

func _ready() -> void:
	if time_trial_display: writing = "Time Trial\nWorld " + str(time_trial_world) + " Best Time: " + ((str(SaveManager.save_game.trial_times[time_trial_world]) + "s") if SaveManager.save_game.trial_times[time_trial_world] != 0.0 else "Unattempted")
	text.text = writing
	text.visible_characters = 0

func _process(_delta: float) -> void: text_box.visible = text.visible_characters != 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		reading = true
		if body.new_scale > scale*1.75: body.modulate = Color(1,1,1,0.66)
		for i in len(writing):
			if not reading or text.visible_characters > len(writing): break
			text_box.modulate = Color(1,1,1,1)
			text.visible_characters += 1
			if is_inside_tree(): await get_tree().create_timer(reading_time*0.01).timeout
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		reading = false
		body.modulate = Color(1,1,1,1)
		for i in text.visible_characters:
			if reading: break
			text_box.modulate = Color(1,1,1,0.33)
			text.visible_characters -= 1
			if is_inside_tree(): await get_tree().create_timer(collapsing_time*0.01).timeout
