extends Node

var time_limit: float
var time_trial: bool
var time_taken: float
var destination := 1
var title_screen := false
var can_pause := true
var attempts := 1
var key: String
var p_scale := Vector2.ONE
const pause_menu_scene := preload("res://tscn/uis/pause_menu.tscn")
const player_scene := preload("res://tscn/elements/player.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var pause_menu := pause_menu_scene.instantiate()
	get_tree().current_scene.add_sibling.call_deferred(pause_menu)
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset") and not title_screen:
		get_tree().paused = false
		Global.can_pause = true
		if get_tree().current_scene.has_meta("attempt_counter") and get_tree().current_scene.get_meta("attempt_counter"): attempts += 1
		if Global.time_trial:
			Global.time_trial = false
			Global.time_limit = 0.0
			Global.time_taken = 0.0
			get_tree().change_scene_to_file("res://tscn/stages/world_" + str(get_tree().current_scene.get_meta("world_id")[0]) + "/" + "stage_selection_" + str(get_tree().current_scene.get_meta("world_id")[0]) + ".tscn")
		get_tree().reload_current_scene.call_deferred()
	if Input.is_action_just_pressed("esc") and can_pause and not title_screen:
		get_tree().paused = not get_tree().paused
	elif !get_window().has_focus() and !get_tree().paused and can_pause and not title_screen: get_tree().paused = true
	if time_trial: time_taken += (delta)
