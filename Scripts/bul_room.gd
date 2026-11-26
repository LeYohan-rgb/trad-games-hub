extends VBoxContainer

@onready var my_plr_lbl = $my_player_panel/my_plr_lbl
@onready var opp_plr_lbl = $opp_player_panel/opp_plr_lbl
@onready var message_lbl = $message_container/message_panel/message_label

#nodes
@onready var my_landing_score = $main_container/sticks_container/bottom_space/my_player_score
@onready var opp_landing_score = $main_container/sticks_container/top_space/opp_player_score

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
	13: [6, "opp", true],
	"my_captured" : 0,
	"opp_captured" : 0,
	"game_turn" : 1
}

@onready var row_nodes : Dictionary = { #THIS IS RELATIVE TOO
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

@onready var stick_nodes : Dictionary = {
	1: $main_container/sticks_container/VBoxContainer/HBoxContainer/stick_1,
	2: $main_container/sticks_container/VBoxContainer/HBoxContainer/stick_2,
	3: $main_container/sticks_container/VBoxContainer/HBoxContainer2/stick_3,
	4: $main_container/sticks_container/VBoxContainer/HBoxContainer2/stick_4,
}

var opp_player_disconnected = false
var game_paused = false
var can_throw_the_sticks = false
var thrown_first_sticks = [false, false]
var thrown_first_sticks_amount = [0, 0]
var stick_amount_turn = 0
var has_thrown_sticks_on_their_turn = false #the throw before moving
var is_host_first_player = false
var game_started = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_up()
	
	if Global.game_mode == 0:
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_disconnected():
	opp_player_disconnected = true

func _on_server_disconnected():
	opp_player_disconnected = true
	
func set_up():
	game_paused = true
	
	set_up_the_board(game_state)
	#SET UP PLAYERS NAMES
	my_plr_lbl.text = return_my_or_opp_plr_string("my")
	opp_plr_lbl.text = return_my_or_opp_plr_string("opp")
	
	message_lbl.text = "Let's select the first player!"
	await get_tree().create_timer(2.0).timeout
	
	if Global.game_mode == 0:
		if multiplayer.is_server():
			message_lbl.text = "Throw the sticks!"
			can_throw_the_sticks = true
		else:
			message_lbl.text = "Waiting for " + client_or_host_player_name_str("host") + " to throw the sticks..."
		game_paused = false
		
func return_is_the_host_str() -> String:
	if multiplayer.is_server():
		return "host"
	else:
		return "client"
		
	return ""
		
func set_up_the_board(current_game_state): #everything dealing with game state is relative
	if Global.game_mode == 0:
		for i in range(1,14):
			if i == 1:
				row_nodes[i].get_node("CenterContainer/Sprite2D").texture = load("res://Graphics/bul_game/" + return_my_or_opp_plr_host_or_client_str("my") +  "_pieces_" + str(current_game_state[i][0]) + ".png")
				continue
			if i == 13:
				row_nodes[i].get_node("CenterContainer/Sprite2D").texture = load("res://Graphics/bul_game/" + return_my_or_opp_plr_host_or_client_str("opp")  +  "_pieces_" + str(current_game_state[i][0]) + ".png")
			else:
				if current_game_state[i][0] >= 1:
					if current_game_state[i][0] != 1:
						row_nodes[i].get_node("Button").text = str(current_game_state[i][0])
					else:
						row_nodes[i].get_node("Button").text = ""
					row_nodes[i].get_node("CenterContainer/Sprite2D").texture = load("res://Graphics/bul_game/" + return_white_or_black_mode_2(i) +"_row_1_" + return_my_or_opp_plr_host_or_client_str(current_game_state[i][1]) + ".png")
				else:
					row_nodes[i].get_node("CenterContainer/Sprite2D").texture = load("res://Graphics/bul_game/" + return_white_or_black_mode_2(i) + "_row_0.png")

func return_white_or_black_mode_2(num) -> String:
	if num % 2 == 0:
		return "black"
	else:
		return "white"
		
func reset_all_variables():
	stick_amount_turn = 0
	has_thrown_sticks_on_their_turn = false
	is_host_first_player = false
	opp_player_disconnected = false
	opp_landing_score.text = ""
	my_landing_score.text = ""
	thrown_first_sticks = [false, false]
	game_started = false
	game_paused = false
	can_throw_the_sticks = false
	set_up_the_board({
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
	13: [6, "opp", true],
	"my_captured" : 0,
	"opp_captured" : 0,
	"game_turn" : 1
})
	
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
	
func return_my_or_opp_plr_host_or_client_str(str) -> String:
	if Global.game_mode == 0:
		if multiplayer.is_server():
			if str == "my":
				return "host"
			else:
				return "client"
		else:
			if str == "my":
				return "client"
			else:
				return "host"
			
	return ""
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func is_it_your_turn_player() -> bool:
	if is_host_first_player:
		if game_state["game_turn"] % 2 == 1: #if the host is first player, and the turn is odd, true
			return true
		else:
			return false #if the host is first player, and the turn is even, false
	else:
		if game_state["game_turn"] % 2 == 0: #if the client is 2nd player, and the turn is even, true
			return true
		else:
			return false #if the client is 2nd player, and the turn is odd, false
	return false
			
func is_it_my_turn() -> bool:
	if multiplayer.is_server() and is_it_your_turn_player():
		return true
	if not multiplayer.is_server() and is_it_your_turn_player():
		return true
	return false
	
func _on_throw_btn_pressed() -> void:
	if can_throw_the_sticks == false:
		return
		
	if game_paused == true:
		return
		
	if Global.game_mode == 0:
		if is_it_my_turn() and not has_thrown_sticks_on_their_turn:
			throw_sticks_animation.rpc(return_random_stick_array())
			return
		
	throw_sticks_animation.rpc(return_random_stick_array())

func return_random_stick_array() -> Array:
	var random_up_down_array = [0, 0, 0, 0] #IF ITS 1 ITS UP. IF ITS 0 ITS DOWN
	for i in range(4):
		random_up_down_array[i] = randi_range(0, 1)
		
	return random_up_down_array
	
func return_int_1_to_4_host_or_client(num) -> int:
	#4 -> 1, 2 -> 3, 3 -> 2, 4 -> 1
	if multiplayer.is_server():
		return num
	else:
		return 5 - num
		
func client_or_host_player_name_str(str) -> String:
	if str == "host":
		return Global.players[0]
	else:
		return Global.players[1]
	
@rpc("any_peer", "call_local", "reliable")
func throw_sticks_animation(my_array):
	can_throw_the_sticks = false
	game_paused = true
	
	if Global.game_mode == 0: #FOR ONLINE MULT
		for i in range(1, 5):
			if my_array[i - 1] == 0:
				stick_nodes[return_int_1_to_4_host_or_client(i)].icon = load("res://Graphics/bul_game/stick_down.png")
			else:
				stick_nodes[return_int_1_to_4_host_or_client(i)].icon = load("res://Graphics/bul_game/stick_up.png")
		
		var total_sum = 0 #SUM OF THE POINTS
		for i in range(4):
			total_sum += my_array[i]
		if total_sum == 0:
			total_sum = 5
			
		if game_started == false and thrown_first_sticks[0] == false: #the host throws first before starting the game
			message_lbl.text = client_or_host_player_name_str("host") + " landed a " + str(total_sum) + "!"
			if multiplayer.is_server():
				my_landing_score.text = str(total_sum)
			else:
				opp_landing_score.text = str(total_sum)
			thrown_first_sticks[0] = true
			thrown_first_sticks_amount[0] = total_sum
			await get_tree().create_timer(2.0).timeout
			if multiplayer.is_server():
				message_lbl.text = "Waiting for " + client_or_host_player_name_str("client") + " to throw the sticks..."
			else:
				can_throw_the_sticks = true
				message_lbl.text = "Throw the sticks!"
			game_paused = false
			return

		if game_started == false and thrown_first_sticks[0] == true: #the client throws second before starting the game
			message_lbl.text = client_or_host_player_name_str("client") + " landed a " + str(total_sum) + "!"
			if multiplayer.is_server():
				opp_landing_score.text = str(total_sum)
			else:
				my_landing_score.text = str(total_sum)
			thrown_first_sticks[1] = true
			thrown_first_sticks_amount[1] = total_sum
			await get_tree().create_timer(2.0).timeout
			
			#DECIDE WHO GOES FIRST
			if thrown_first_sticks_amount[0] == thrown_first_sticks_amount[1]:
				message_lbl.text = "Both players landed the first score!"
				await get_tree().create_timer(2.0).timeout
				var random_player_chosen = return_random_int_0_to_1()
				if random_player_chosen == 0: #host was chosen
					is_host_first_player = true
					if multiplayer.is_server():
						opp_landing_score.text = ""
					else:
						my_landing_score.text = ""
					message_lbl.text = client_or_host_player_name_str("host") + " was randomly chosen as the first player."
					await get_tree().create_timer(2.0).timeout
					opp_landing_score.text = ""
					my_landing_score.text = ""
					message_lbl.text = "It's " + client_or_host_player_name_str("host") + "'s turn!"
					can_throw_the_sticks = true
				else:
					is_host_first_player = false
					if multiplayer.is_server():
						my_landing_score.text = ""
					else:
						opp_landing_score.text = ""
					message_lbl.text = client_or_host_player_name_str("client") + " was randomly chosen as the first player."
					await get_tree().create_timer(2.0).timeout
					opp_landing_score.text = ""
					my_landing_score.text = ""
					message_lbl.text = "It's " + client_or_host_player_name_str("host") + "'s turn!"
				game_paused = false
				game_started = true
			else:
				if thrown_first_sticks_amount[0] > thrown_first_sticks_amount[1]: #host goes first
					is_host_first_player = true
					message_lbl.text = client_or_host_player_name_str("host") + " landed the highest score!"
					if multiplayer.is_server():
						opp_landing_score.text = ""
					else:
						my_landing_score.text = ""
					await get_tree().create_timer(2.0).timeout
					opp_landing_score.text = ""
					my_landing_score.text = ""
					message_lbl.text = "It's " + client_or_host_player_name_str("host") + "'s turn!"
					if multiplayer.is_server():
						can_throw_the_sticks = true
					game_paused = false
					game_started = true
				else:
					is_host_first_player = false
					message_lbl.text = client_or_host_player_name_str("client") + " landed the highest score!"
					if multiplayer.is_server():
						my_landing_score.text = ""
					else:
						opp_landing_score.text = ""
					await get_tree().create_timer(2.0).timeout
					opp_landing_score.text = ""
					my_landing_score.text = ""
					message_lbl.text = "It's " + client_or_host_player_name_str("client") + "'s turn!"
					if not multiplayer.is_server():
						can_throw_the_sticks = true
					game_paused = false
					game_started = true
			
		message_lbl.text = client_or_host_player_name_str(whose_turn_is_it_str()) + " landed a " + str(total_sum) + "!"
		if multiplayer.is_server() == is_it_host(whose_turn_is_it_str()):
			my_landing_score.text = str(total_sum)
			await get_tree().create_timer(2.0).timeout
			has_thrown_sticks_on_their_turn = true
			stick_amount_turn = total_sum
		else:
			opp_landing_score.text = str(total_sum)
			await get_tree().create_timer(2.0).timeout
		message_lbl.text = "It's " + client_or_host_player_name_str(whose_turn_is_it_str()) + "'s turn!"
		game_paused = false
		
func is_it_host(str) -> bool:
	if str == "host":
		return true
	else:
		return false
		
func whose_turn_is_it_str() -> String:
	if is_host_first_player:
		if game_state["game_turn"] % 2 == 1: #if the host is first player, and the turn is odd, it is THE HOST
			return "host"
		else:
			return "client" #if the host is first player, and the turn is even, false
	else:
		if game_state["game_turn"] % 2 == 0: #if the client is 2nd player, and the turn is even, it is THE CLIENT
			return "client"
		else:
			return "host" #if the client is 2nd player, and the turn is odd, false

func return_random_int_0_to_1():
	var random_array = [0,1]
	random_array.shuffle()
	return random_array[0]
