extends Control

@onready var player_1_label = $player_1_panel/Label
@onready var player_2_label = $player_2_panel/Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if Global.game_mode == 0:
		set_up()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up():
	if multiplayer.is_server():
		player_1_label.text = Global.players[0]
		player_2_label.text = Global.players[1]
	else:
		player_1_label.text = Global.players[1]
		player_2_label.text = Global.players[0]
