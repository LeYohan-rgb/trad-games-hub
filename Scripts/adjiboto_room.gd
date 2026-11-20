extends Control

@onready var player_1_label = $player_1_panel/Label
@onready var player_2_label = $player_2_panel/Label
@onready var message_label = $Control/message_label

@onready var game_holes= {
	1: $HBoxContainer/holes_container/btn_1_1,
	2: $HBoxContainer/holes_container/btn_1_2,
	3: $HBoxContainer/holes_container/btn_1_3,
	4: $HBoxContainer/holes_container/btn_1_4,
	5: $HBoxContainer/holes_container/btn_1_5,
	6: $HBoxContainer/holes_container/btn_2_1,
	7: $HBoxContainer/holes_container/btn_2_2,
	8: $HBoxContainer/holes_container/btn_2_3,
	9: $HBoxContainer/holes_container/btn_2_4,
	10: $HBoxContainer/holes_container/btn_2_5
}

var game_state = {
	1: 10,
	2: 10,
	3: 10,
	4: 10,
	5: 10,
	6: 10,
	7: 10,
	8: 10,
	9: 10,
	10: 10,
	"turn": 0,
	"player_1_stones": 0,
	"player_2_stones": 0,
	"game_turn": 1,
}

var game_paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if Global.game_mode == 0:
		set_up()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_up():
	message_label.text = "It's " + Global.players[0] + "'s turn!"
	if multiplayer.is_server():
		player_1_label.text = Global.players[0]
		player_2_label.text = Global.players[1]
	else:
		player_1_label.text = Global.players[1]
		player_2_label.text = Global.players[0]


func _on_holes_container_performed_move_on_hole(hole_num: Variant) -> void:
	if game_paused == true:
		return
		
		
	if multiplayer.is_server() and game_state["turn"] == 0 and game_paused == false:
		is_move_legal(hole_num, 0)
			
		#THE HOST PLAYED!
	if not multiplayer.is_server() and game_state["turn"] == 1 and game_paused == false:
		is_move_legal(hole_num, 1)
		#THE CLIENT PLAYED!
		pass
	

func is_move_legal(hole_num, player):
	#STILL NOT ADDED THE 10 TURN RULE YET
	if game_state[hole_num] > 1:
		perform_move.rpc(hole_num, player)
	else:
		illegal_move_message()

func illegal_move_message():
	game_paused = true
	message_label.text = "You must play a hole with more than one stone!"
	await get_tree().create_timer(2.0).timeout
	message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false

@rpc("any_peer", "call_local", "reliable")
func perform_move(hole_num, player):
	game_paused = true
	
	
	if multiplayer.is_server():
		update_game_state(hole_num, player, 0)
	else:
		update_game_state(hole_num, player, 1)

func update_game_state(hole_num, player, plr_interface):

	if plr_interface == 0:
		if player == 0:
			message_label.text = Global.players[player] + " distributed " + str(game_state[hole_num] - 1) + " stones!"
			game_state[hole_num] = 1
			game_holes[hole_num].text = str(1)
		else:
			message_label.text = Global.players[player] + " distributed " + str(game_state[5 + hole_num] - 1) + " stones!"
			game_state[5 + hole_num] = 1
			game_holes[5 + hole_num].text = str(1)
	else:
		if player == 0:
			message_label.text = Global.players[player] + " distributed " + str(game_state[5 + hole_num] - 1) + " stones!"
			game_state[5 + hole_num] = 1
			game_holes[5 + hole_num].text = str(1)
		else:
			message_label.text = Global.players[player] + " distributed " + str(game_state[hole_num] - 1) + " stones!"
			game_state[hole_num] = 1
			game_holes[hole_num].text = str(1)
