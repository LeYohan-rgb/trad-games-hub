extends VBoxContainer

@onready var my_plr_lbl = $my_player_panel/my_plr_lbl
@onready var opp_plr_lbl = $opp_player_panel/opp_plr_lbl
@onready var message_lbl = $message_container/message_panel/message_label


var game_paused = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_up()
	
func set_up():
	game_paused = true
	
	#SET UP PLAYERS NAMES
	my_plr_lbl.text = return_my_or_opp_plr_string("my")
	opp_plr_lbl.text = return_my_or_opp_plr_string("opp")
	
	message_lbl.text = "Let's select the first player!"
	
	
func reset_all_variables():
	game_paused = false
	

func return_my_or_opp_plr_string(str) -> String:
	if Global.game_mode == 0:
		if multiplayer.is_server():
			if str == "my":
				return Global.players[0]
			else:
				return Global.players[1]
		else:
			if str == "my":
				return Global.players[1]
			else:
				return Global.players[0]
			
	return ""
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
