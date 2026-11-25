extends VBoxContainer

@onready var my_plr_lbl = $my_player_panel/my_plr_lbl
@onready var opp_plr_lbl = $opp_player_panel/opp_plr_lbl
@onready var message_lbl = $message_container/message_panel/message_label


var game_state : Dictionary = { #THE GAME STATE IS RELATIVE. [no, my_or_opp, direction] true -> enemy base.
	1: [6, "my", true],
	2: [0, "none", true],
	3: [0, "none", true],
	4: [0, "none", true],
	5: [0, "none", true],
	6: [0, "none", true],
	7: [0, "none", true],
	8: [0, "none", true],
	9: [0, "none", true],
	10: [0, "none", true],
	11: [0, "none", true],
	12: [0, "none", true],
	13: [0, "none", true],
	"my_captured" : 0,
	"opp_captured" : 0
}

var row_nodes : Dictionary = { #THIS IS RELATIVE TOO
	1: $main_container/board_container/Row1,
	2: $main_container/board_container/Row2,
	3: $main_container/board_container/Row3,
	4: $main_container/board_container/Row4,
	5: $main_container/board_container/Row5,
	6: $main_container/board_container/Row6,
	7: $main_container/board_container/Row7,
	8: $main_container/board_container/Row8,
	9: $main_container/board_container/Row9,
	10: $main_container/board_container/Row10,
	11: $main_container/board_container/Row11,
	12: $main_container/board_container/Row12,
	13: $main_container/board_container/Row13
}

var game_paused = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_up()
	
	if Global.game_mode == 0:
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_disconnected():
	pass

func _on_server_disconnected():
	pass
	
func set_up():
	game_paused = true
	
	set_up_the_board(game_state)
	#SET UP PLAYERS NAMES
	my_plr_lbl.text = return_my_or_opp_plr_string("my")
	opp_plr_lbl.text = return_my_or_opp_plr_string("opp")
	
	message_lbl.text = "Let's select the first player!"

func return_is_the_host_str() -> String:
	if multiplayer.is_server():
		return "host"
	else:
		return "client"
		
	return ""
		
func set_up_the_board(current_game_state): #everything dealing with game state is relative
	if Global.game_mode == 0:
		if multiplayer.is_server(): #host POV
			for i in range(1,14):
				if i in [1, 13]:
					row_nodes[i].get_node("Sprite2D").texture = load("res://Graphics/bul_game/" + return_is_the_host_str() +  "_pieces_" + str(current_game_state[i][0]) + ".png")
				else:
					pass
		else: #client POV
			pass
	
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
