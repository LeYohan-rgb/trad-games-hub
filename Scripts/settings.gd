extends VBoxContainer

@onready var users_name = $VBoxContainer/HBoxContainer/users_name

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	users_name.text = Global.player_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_line_edit_text_changed(new_text: String) -> void:
	Global.player_name = new_text


func _on_go_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/starting_screen.tscn")
