extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mult_btn_pressed() -> void:
	Global.game_mode = 0
	get_tree().change_scene_to_file("res://Scenes/hosting_room.tscn")
	


func _on_bot_btn_pressed() -> void:
	
	Global.game_mode = 1
	#GO TO ADJIBOTO BOT
	if Global.playing_game == 1:
		get_tree().change_scene_to_file("res://Scenes/adjiboto_room.tscn")


func _on_go_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game_selector.tscn")
