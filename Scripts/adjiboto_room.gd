extends Control

@onready var player_1_label = $player_1_panel/Label
@onready var player_2_label = $player_2_panel/Label
@onready var message_label = $Control/message_label

var modulate_color = "e8dc0e"

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
	
	var amount_of_stones_removed = int(get_stone(player, is_the_host(), hole_num).text) - 1
	update_game_state(hole_num, player, is_the_host())
	await get_tree().create_timer(0.5).timeout
	loop_through_holes(hole_num, player, is_the_host(), amount_of_stones_removed)

		
func is_the_host() -> int:
	if multiplayer.is_server():
		return 0
	else:
		return 1

func get_stone_by_index(player, plr_interface, hole_num):
	if plr_interface == 0:
		if player == 0:
			return hole_num
		else:
			return mod_10_index(5 + hole_num)
	else:
		if player == 0:
			return mod_10_index(5 + hole_num)
		else:
			return hole_num
func get_stone(player, plr_interface, hole_num):
	if plr_interface == 0:
		if player == 0:
			return game_holes[hole_num]
		else:
			return game_holes[mod_10_index(5 + hole_num)]
	else:
		if player == 0:
			return game_holes[mod_10_index(5 + hole_num)]
		else:
			return game_holes[hole_num]
		
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

func loop_through_holes(hole_num, plr, plr_interface, stones_removed):
	for i in range(stones_removed):
		game_state[get_stone_by_index(plr, plr_interface, mod_10_index(hole_num + i + 1))] += 1
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).text = str(int(get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).text) + 1)
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).modulate = modulate_color
		await get_tree().create_timer(0.5).timeout
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).modulate = "ffffff"
		
	game_state["game_turn"] += 1
	if game_state["turn"] == 0:
		game_state["turn"] = 1
	else:
		game_state["turn"] = 0
	message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false

func mod_10_index(num):
	if num % 10 == 0:
		return 10
	else:
		return num % 10
