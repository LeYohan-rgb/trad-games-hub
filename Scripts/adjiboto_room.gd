extends Control

@onready var player_1_label = $player_1_panel/Label
@onready var player_2_label = $player_2_panel/Label
@onready var message_label = $Control/message_label

@onready var plr_1_stones_lbl = $HBoxContainer/adjiboto_boat_1/Label
@onready var plr_2_stones_lbl = $HBoxContainer/adjiboto_boat_2/Label
@onready var turn_lbl = $Control2/turn_panel/turn_lbl
@onready var pause_panel = $Control2/pause_panel
@onready var pause_btn = $Control2/pause_button
@onready var disconnected_lbl = $player_2_panel/disconnected_lbl
@onready var winning_panel = $Control2/winning_panel
@onready var winning_lbl = $Control2/winning_panel/Panel/winning_lbl

@onready var plr_2_stones_bg = $HBoxContainer/adjiboto_boat_2/ColorRect
@onready var plr_1_stones_bg = $HBoxContainer/adjiboto_boat_1/ColorRect

var modulate_color_1 = "e8dc0e"
var modulate_color_2 = "00f3fd"
var catch_modulate_color = "ff0000"
var opposite_player_disconnected : bool = false



var holes_used_in_first_stage = []

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

var is_pausing_game = false
var game_paused = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if Global.game_mode == 0:
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		set_up()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if opposite_player_disconnected:
		go_to_player_disconnected_announce()

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
		
	#CHECK IF THE PLAYER DISCONNECTED
	if opposite_player_disconnected:
		message_label.text = "..."
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
		
		#10 TURN RULE
		if hole_num in holes_used_in_first_stage and game_state["game_turn"] <= 10:
			illegal_move_message_first_stage()
			return
		
		if game_state["game_turn"] <= 10:
			holes_used_in_first_stage.append(hole_num)
			game_holes[hole_num].self_modulate.a = 0.8
			
		perform_move.rpc(hole_num, player)
	else:
		illegal_move_message()

func illegal_move_message():
	game_paused = true
	message_label.text = "You must play a hole with more than one stone!"
	await get_tree().create_timer(2.0).timeout
	message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false
	
func illegal_move_message_first_stage():
	game_paused = true
	message_label.text = "You must play each of the holes before playing the same hole!"
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
			message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[hole_num] - 1) + " stones!"
			game_state[hole_num] = 1
			game_holes[hole_num].text = str(1)
		else:
			message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[5 + hole_num] - 1) + " stones!"
			game_state[5 + hole_num] = 1
			game_holes[5 + hole_num].text = str(1)
	else:
		if player == 0:
			message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[5 + hole_num] - 1) + " stones!"
			game_state[5 + hole_num] = 1
			game_holes[5 + hole_num].text = str(1)
		else:
			message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[hole_num] - 1) + " stones!"
			game_state[hole_num] = 1
			game_holes[hole_num].text = str(1)

func loop_through_holes(hole_num, plr, plr_interface, stones_removed):
	#DEBUG VALUE: 0.01 MAX
	var time_per_stone = clamp(0.1, 5.0 / stones_removed, 0.5)
	if Global.is_debugging:
		time_per_stone = 0.01
	var modulate_color = modulate_color_1 if game_state["turn"] == 0 else modulate_color_2
	var ending_hole
	
	for i in range(stones_removed):
		game_state[get_stone_by_index(plr, plr_interface, mod_10_index(hole_num + i + 1))] += 1
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).text = str(int(get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).text) + 1)
		message_label.text = Global.players[plr] + " distributed " + str(1 + i) + " out of " + str(stones_removed) + " stones!"
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).modulate = modulate_color
		await get_tree().create_timer(time_per_stone).timeout
		get_stone(plr, plr_interface, mod_10_index(hole_num + i + 1)).modulate = "ffffff"
		
		if i == stones_removed - 1:
			ending_hole = get_stone_by_index(plr, plr_interface, mod_10_index(hole_num + i + 1))
			
	#CHECK IF CAN CAPTURE!!
	var can_capture = true
	var iterative_capture = 0
	while can_capture:
		var stones_catched = game_state[get_stone_by_index(plr, plr_interface, mod_10_index(hole_num + stones_removed + 1 + iterative_capture))]
		if is_in_a_capture_sequence(stones_catched) and game_state["game_turn"] != 1:
			get_stone(plr, plr_interface, mod_10_index(hole_num + stones_removed + 1 + iterative_capture)).modulate = catch_modulate_color
			message_label.text = Global.players[game_state["turn"]] + "captures " + str(stones_catched) + " stones!"
			await get_tree().create_timer(1.0).timeout
			
			#CATCHED
			catched_stones_by_plr(stones_catched)
			game_state[get_stone_by_index(plr, plr_interface, mod_10_index(hole_num + stones_removed + 1 + iterative_capture))] = 0
			get_stone(plr, plr_interface, mod_10_index(hole_num + stones_removed + 1 + iterative_capture)).text = str(0)
			get_stone(plr, plr_interface, mod_10_index(hole_num + stones_removed + 1 + iterative_capture)).modulate = "ffffff"
			iterative_capture += 1
		else:
			can_capture = false
	
	#CHECK IF A PLAYER HAS NO LEGAL MOVES LEFT
	check_if_legal_moves_left()
	
func check_if_legal_moves_left():
	var no_legal_moves = true
	#if the current turn is the 1st player, check if THE CLIENT has moves left
	if game_state["turn"] == 0:
		if multiplayer.is_server():
			for i in range(6,11): #For the host POV, check if the client has moves left
				if game_state[i] >= 2:
					no_legal_moves = false
		else:
			for i in range(1,6): #for the client POV, check if themselves have moves left
				if game_state[i] >= 2:
					no_legal_moves = false
				
	else:
		if multiplayer.is_server():
			for i in range(1,6): #for the host POV, check if themselves have moves left
				if game_state[i] >= 2:
					no_legal_moves = false
		else:
			for i in range(6,11): #for the client POV, check if the host has moves left
				if game_state[i] >= 2:
					no_legal_moves = false
					
	if no_legal_moves == true: #END GAME
		end_game()
	else:
		go_to_next_turn()

func calculate_stones_left():
	
	var stones_remaining : int = 0
	if game_state["turn"] == 0: #WE CALCULATE THE CLIENT'S BALLS
		if multiplayer.is_server(): #Calculate the client's balls
			for i in range(6, 11):
				stones_remaining += game_state[i]
				
		else: #calculate my own balls (the client)
			for i in range(1, 6):
				stones_remaining += game_state[i]
	else: #WE CALCULATE THE HOST'S BALLS
		if multiplayer.is_server(): #Calculate my own balls (the host)
			for i in range(1, 6):
				stones_remaining += game_state[i]
				
		else: #calculate host's balls
			for i in range(6, 11):
				stones_remaining += game_state[i]
				
	return (50 - stones_remaining)
	
func refill_time():
	var modulate_color = modulate_color_2 if game_state["turn"] == 0 else modulate_color_1
	for i in range(5):
		if game_state["turn"] == 0: #WE REFILL THE CLIENT'S BALLS
			
			if multiplayer.is_server(): #refill client (the other)
				game_state["player_2_stones"] -= (10 - game_state[5 + 1 + i])
				plr_2_stones_lbl.text = str(game_state["player_2_stones"])
				game_holes[5 + i + 1].text = "10"
				game_state[5 + i + 1] = 10
				game_holes[5 + i + 1].modulate = modulate_color # change color accordingly
				await get_tree().create_timer(0.5).timeout
				game_holes[5 + i + 1].modulate = "ffffff"
				
			else: #refill client (my own)
				game_state["player_2_stones"] -= (10 - game_state[1 + i])
				plr_1_stones_lbl.text = str(game_state["player_2_stones"])
				game_state[i + 1] = 10
				game_holes[i + 1].text = "10"
				game_holes[i + 1].modulate = modulate_color # change color accordingly
				await get_tree().create_timer(0.5).timeout
				game_holes[i + 1].modulate = "ffffff"
		else: #WE REFILL THE HOST'S BALLS

			if multiplayer.is_server(): #refill host (my own)
				game_state["player_1_stones"] -= (10 - game_state[1 + i])
				plr_1_stones_lbl.text = str(game_state["player_1_stones"])
				game_state[i + 1] = 10
				game_holes[i + 1].text = "10"
				game_holes[i + 1].modulate = modulate_color # change color accordingly
				await get_tree().create_timer(0.5).timeout
				game_holes[i + 1].modulate = "ffffff"
					
			else: #refill client (the other)
				game_state["player_1_stones"] -= (10 - game_state[5 + 1 + i])
				plr_2_stones_lbl.text = str(game_state["player_1_stones"])
				game_state[5 + i + 1] = 10
				game_holes[5 + i + 1].text = "10"
				game_holes[5 + i + 1].modulate = modulate_color # change color accordingly
				await get_tree().create_timer(0.5).timeout
				game_holes[5 + i + 1].modulate = "ffffff"
	

	
func end_game():
	message_label.text = Global.players[opposite_turn()] + " has no legal moves left!"
	await get_tree().create_timer(2.0).timeout
	# CHECK IF DRAW
	if game_state["player_" + return_opp_player_index_from_one_to_two() + "_stones"] >= calculate_stones_left():
		modulate_player_boat(0) #highlight the boat
		
		message_label.text = "But they have enough stones to refill all of their holes!"
			
		
		await refill_time() #refill all holes back
		
		modulate_player_boat(1)
		
		message_label.text = "The game ends in a draw!"
		
		await get_tree().create_timer(2.0).timeout
		end_the_game_and_enter_end_screen(2) #0 host wins, 1 client wins, 2 draw
	else:
		message_label.text = "They do not have enough stones to refill all of their holes!"
		await get_tree().create_timer(2.0).timeout
		message_label.text = Global.players[game_state["turn"]] + " wins the game!"
		await get_tree().create_timer(2.0).timeout
		end_the_game_and_enter_end_screen(game_state["turn"])
		
func end_the_game_and_enter_end_screen(outcome : int):
	pause_panel.hide()
	pause_btn.hide()
	winning_panel.show()
	
	if outcome == 0:
		winning_lbl.text = Global.players[0] + " WINS!"
		winning_lbl.add_theme_color_override("font_color", Color(modulate_color_1))
	if outcome == 1:
		winning_lbl.text = Global.players[1] + " WINS!"
		winning_lbl.add_theme_color_override("font_color", Color(modulate_color_2))
	if outcome == 2:
		winning_lbl.text = "DRAW"
		winning_lbl.add_theme_color_override("font_color", Color("#ffffff"))

func modulate_player_boat(on_or_off):
	if on_or_off == 0: #if 0, modulate!
		if game_state["turn"] == 0:
			if multiplayer.is_server():
				plr_2_stones_bg.self_modulate.a = 0.5
			else:
				plr_1_stones_bg.self_modulate.a = 0.5
		else:
			if multiplayer.is_server():
				plr_1_stones_bg.self_modulate.a = 0.5
			else:
				plr_2_stones_bg.self_modulate.a = 0.5
	else: #if not, then un-modulate.
		if game_state["turn"] == 0:
			if multiplayer.is_server():
				plr_2_stones_bg.self_modulate.a = 1
			else:
				plr_1_stones_bg.self_modulate.a = 1
		else:
			if multiplayer.is_server():
				plr_1_stones_bg.self_modulate.a = 1
			else:
				plr_2_stones_bg.self_modulate.a = 1
		
func return_opp_player_index_from_one_to_two() -> String:
	if game_state["turn"] == 0:
		return "2"
	else:
		return "2"
		
func opposite_turn():
	if game_state["turn"] == 0:
		return 1
	else:
		return 0
		
func catched_stones_by_plr(stones_catched):
	if game_state["turn"] == 0:
		if multiplayer.is_server():
			game_state["player_1_stones"] += stones_catched
			plr_1_stones_lbl.text = str(int(plr_1_stones_lbl.text) + stones_catched)
		else:
			game_state["player_1_stones"] += stones_catched
			plr_2_stones_lbl.text = str(int(plr_2_stones_lbl.text) + stones_catched)
	else:
		if multiplayer.is_server():
			game_state["player_2_stones"] += stones_catched
			plr_2_stones_lbl.text = str(int(plr_2_stones_lbl.text) + stones_catched)
		else:
			game_state["player_2_stones"] += stones_catched
			plr_1_stones_lbl.text = str(int(plr_1_stones_lbl.text) + stones_catched)

func is_in_a_capture_sequence(num) -> bool:
	if num == 1 or num == 3 or num == 5:
		return true
	else:
		return false

func go_to_next_turn():

	if Global.is_debugging:
		if game_state["game_turn"] == 12:
			game_state["player_2_stones"] = 30
			if multiplayer.is_server():
				plr_2_stones_lbl.text = str(30)
				for i in range(6,11):
					game_state[i] = 1
					game_holes[i].text = '1'
			else:
				plr_1_stones_lbl.text = str(30)
				for i in range(1,6):
					game_state[i] = 1
					game_holes[i].text = '1'
	
	
	game_state["game_turn"] += 1
	update_turn_counter()
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
		
func update_turn_counter():
	turn_lbl.text = "TURN " + str(game_state["game_turn"])
	
	if game_state["game_turn"] == 11:
		for i in range(1, 6):
			game_holes[i].self_modulate.a = 1


func _on_pause_button_pressed() -> void:
	if is_pausing_game:
		pause_panel.hide()
		is_pausing_game = false
		pause_btn.icon = load("res://Graphics/general_icons/pause_icon.png")
		return
	
	is_pausing_game = true
	pause_panel.show()
	pause_btn.icon = load("res://Graphics/general_icons/resume_icon.png")
	
	
		
		


func _on_resign_btn_pressed() -> void:
	if opposite_player_disconnected: #obv if the opp player disconnected, you can't possibly resign
		return
		
	if game_paused == true:
		return
		
	is_pausing_game = false
	game_paused = true
	pause_panel.hide()
	pause_btn.icon = load("res://Graphics/general_icons/pause_icon.png")
	if multiplayer.is_server():
		resign_signal.rpc(0)
	else:
		resign_signal.rpc(1)
		
@rpc("any_peer", "call_local", "reliable")
func resign_signal(player_resign):
	game_paused = true
	message_label.text = Global.players[player_resign] + " wants to resign!"
	await get_tree().create_timer(2.0).timeout
	message_label.text = Global.players[opp_plr(player_resign)] + " wins the game!"
	await get_tree().create_timer(2.0).timeout
	end_the_game_and_enter_end_screen(opp_plr(player_resign))

func opp_plr(num):
	if num == 0:
		return 1
	else:
		return 0


func _on_quit_game_btn_pressed() -> void:
	if game_paused == true:
		return
	
	reset_all_variables()
	
	announce_disconnected_player.rpc()
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://Scenes/game_selector.tscn")
	
@rpc("any_peer", "call_remote", "reliable")
func announce_disconnected_player():
	opposite_player_disconnected = true
	
func reset_all_variables():
	opposite_player_disconnected = false
	winning_panel.hide()
	disconnected_lbl.hide()
	pause_panel.hide()
	pause_btn.icon = load("res://Graphics/general_icons/pause_icon.png")
	holes_used_in_first_stage = []
	plr_1_stones_lbl.text = "0"
	plr_2_stones_lbl.text = "0"
	for i in range(1, 11):
		game_holes[i].text = "0"
	game_state = {1: 10, 2: 10, 3: 10, 4: 10, 5: 10, 6: 10, 7: 10, 8: 10, 9: 10, 10: 10, "turn": 0, "player_1_stones": 0, "player_2_stones": 0, "game_turn": 1,}
	is_pausing_game = false
	game_paused = false
	Global.after_leaving_a_game()

func _on_peer_disconnected(id : int) -> void:
	opposite_player_disconnected = true
	
func _on_server_disconnected():
	opposite_player_disconnected = true

func go_to_player_disconnected_announce():
	if opposite_player_disconnected == false:
		return
	disconnected_lbl.show()
	disconnected_lbl.text = Global.players[1] + " disconnected."
