extends Control

signal game_resumed

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
@onready var win_quit_game_btn = $Control2/winning_panel/HBoxContainer/win_quit_game_btn
@onready var player_choser = $Control/first_plr_choser
@onready var replay_btn = $Control2/winning_panel/HBoxContainer/replay_btn

@onready var plr_2_stones_bg = $HBoxContainer/adjiboto_boat_2/ColorRect
@onready var plr_1_stones_bg = $HBoxContainer/adjiboto_boat_1/ColorRect

var modulate_color_1 = "e8dc0e"
var modulate_color_2 = "00f3fd"
var catch_modulate_color = "ff0000"
var opposite_player_disconnected : bool = false
var plr_disconnected_index : int = 0
var bot_wait_time : float = 5.0


var going_to_replay : bool = false
var holes_used_in_first_stage = []
var holes_used_in_first_stage_bot = []
var replay_agreement = [false, false]
var bot_turn : int = 0

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
	
	if Global.game_mode == 1:
		set_up()
		
	if Global.game_mode == 0:
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		set_up()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if opposite_player_disconnected:
		go_to_player_disconnected_announce()

func set_up():
	winning_panel.hide()
	
	if Global.game_mode == 1:
		if Global.is_debugging:
			bot_wait_time = 1.0
		game_paused = true
		message_label.text = "Who makes the first move?"
		player_choser.show()
		player_1_label.text = Global.player_name
		player_2_label.text = "BOT"
		return
		
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
		
	if Global.game_mode == 1:
		if bot_turn != game_state["turn"]:
			is_move_legal(hole_num, 0)
			return
		else:
			return
			
	if multiplayer.is_server() and game_state["turn"] == 0 and game_paused == false:
		is_move_legal(hole_num, 0)
			
		#THE HOST PLAYED!
	if not multiplayer.is_server() and game_state["turn"] == 1 and game_paused == false:
		is_move_legal(hole_num, 1)
		#THE CLIENT PLAYED!
	

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
			
		if Global.game_mode == 1:
			perform_move(hole_num, 0)
			return
			
		perform_move.rpc(hole_num, player)
	else:
		illegal_move_message()

func illegal_move_message():
	game_paused = true
	message_label.text = "You must play a hole with more than one stone!"
	await get_tree().create_timer(2.0).timeout
	
	if Global.game_mode == 1: #WHEN PLAYING WITH BOT
		message_label.text = "It's " + Global.player_name + "'s turn!"
		game_paused = false
		game_resumed.emit()
		return
		
	message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false
	game_resumed.emit()
	
func illegal_move_message_first_stage():
	game_paused = true
	message_label.text = "You must play each of the holes before playing the same hole!"
	await get_tree().create_timer(2.0).timeout
	
	if Global.game_mode == 1: #WHEN PLAYING WITH BOT
		message_label.text = "It's " + Global.player_name + "'s turn!"
		game_paused = false
		game_resumed.emit()
		return
		
	message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false
	game_resumed.emit()

@rpc("any_peer", "call_local", "reliable")
func perform_move(hole_num, player):
	game_paused = true
	
	if Global.game_mode == 1: #WHEN PLAYING BOT
		var amount_of_stones_removed = int(get_stone(player, 0, hole_num).text) - 1
		update_game_state(hole_num, player, 0)
		await get_tree().create_timer(0.5).timeout
		loop_through_holes(hole_num, player, 0, amount_of_stones_removed)
		return
	
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
			if Global.game_mode == 1:
				message_label.text = return_player_or_bot_str(player, true) + " distributed 1 out of " + str(game_state[hole_num] - 1) + " stones!"
			else:
				message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[hole_num] - 1) + " stones!"
			game_state[hole_num] = 1
			game_holes[hole_num].text = str(1)
		else:
			if Global.game_mode == 1:
				message_label.text = return_player_or_bot_str(player, true) + " distributed 1 out of " + str(game_state[5 + hole_num] - 1) + " stones!"
			else:
				message_label.text = Global.players[player] + " distributed 1 out of " + str(game_state[5 + hole_num] - 1) + " stones!"
			game_state[5 + hole_num] = 1
			game_holes[5 + hole_num].text = str(1)
	else:
		print("THIS IS RUNNING")
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
		
		if Global.game_mode == 1: # IF PLAYING BOT
			message_label.text = return_player_or_bot_str(plr, true) + " distributed " + str(1 + i) + " out of " + str(stones_removed) + " stones!"
		else:
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
			
			if Global.game_mode == 1:
				message_label.text = return_player_or_bot_str(plr, true) + " captures " + str(stones_catched) + " stones!"
			else:
				message_label.text = Global.players[game_state["turn"]] + " captures " + str(stones_catched) + " stones!"
				
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
	
	#FOR THE BOT:
	if Global.game_mode == 1:
		if game_state["turn"] == 0: 
			if bot_turn == 0: #CHECK FOR THE PLAYER
				for i in range(1,6):
					if game_state[i] >= 2:
						no_legal_moves = false
			else: #CHECK FOR THE BOT
				for i in range(6,11):
					if game_state[i] >= 2:
						no_legal_moves = false
		else:
			if bot_turn == 0: #CHECK FOR THE BOT
				for i in range(6,11):
					if game_state[i] >= 2:
						no_legal_moves = false
			else: #CHECK FOR THE PLAYER
				for i in range(1,6):
					if game_state[i] >= 2:
						no_legal_moves = false
		
		if no_legal_moves == true: #END GAME
			end_game_bot() #still not yet botosized
		else:
			go_to_next_turn() #still not yet botosized
		return
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
	
	if Global.game_mode == 1:
		message_label.text = return_player_or_bot_str(opposite_turn_for_bot_mode(), true) + " has no legal moves left!"
	
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
	
	if Global.game_mode == 1:
		if outcome == 0:
			if bot_turn == 0:
				winning_lbl.text = "THE BOT WINS!"
				winning_lbl.add_theme_color_override("font_color", Color(modulate_color_2))
			else:
				winning_lbl.text = Global.player_name + " WINS!"
				winning_lbl.add_theme_color_override("font_color", Color(modulate_color_1))
		if outcome == 1:
			if bot_turn == 0:
				winning_lbl.text = Global.player_name + " WINS!"
				winning_lbl.add_theme_color_override("font_color", Color(modulate_color_1))
			else:
				winning_lbl.text = "THE BOT WINS!"
				winning_lbl.add_theme_color_override("font_color", Color(modulate_color_2))
		if outcome == 2:
			winning_lbl.text = "DRAW"
			winning_lbl.add_theme_color_override("font_color", Color("#ffffff"))
		return
	
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
	if Global.game_mode == 1:
		if game_state["turn"] == 0:
			if bot_turn == 0:
				game_state["player_2_stones"] += stones_catched
				plr_2_stones_lbl.text = str(int(plr_2_stones_lbl.text) + stones_catched)
			else:
				game_state["player_1_stones"] += stones_catched
				plr_1_stones_lbl.text = str(int(plr_1_stones_lbl.text) + stones_catched)
		else:
			if bot_turn == 0:
				game_state["player_1_stones"] += stones_catched
				plr_1_stones_lbl.text = str(int(plr_1_stones_lbl.text) + stones_catched)
			else:
				game_state["player_2_stones"] += stones_catched
				plr_2_stones_lbl.text = str(int(plr_2_stones_lbl.text) + stones_catched)
		return
	
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
		pass
#		if game_state["game_turn"] == 12:
#			game_state["player_2_stones"] = 30
#			if multiplayer.is_server():
#				plr_2_stones_lbl.text = str(30)
#				for i in range(6,11):
#					game_state[i] = 1
#					game_holes[i].text = '1'
#			else:
#				plr_1_stones_lbl.text = str(30)
#				for i in range(1,6):
#					game_state[i] = 1
#					game_holes[i].text = '1'
	
	
	game_state["game_turn"] += 1
	update_turn_counter()
	if game_state["turn"] == 0:
		game_state["turn"] = 1
	else:
		game_state["turn"] = 0
		
	if Global.game_mode == 1:
		message_label.text = "It's " + return_player_or_bot_str(return_player_or_bot_turn(), false) + "'s turn!"
		if game_state["turn"] == bot_turn:
			bot_move()
	else:
		message_label.text = "It's " + Global.players[game_state["turn"]] + "'s turn!"
	game_paused = false
	game_resumed.emit()

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
	
	if Global.game_mode == 1:
		resign_signal_bot()
		return
		
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

func quit_game_btn():
	reset_all_variables()
	
	announce_disconnected_player.rpc()
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://Scenes/game_selector.tscn")
	
func _on_quit_game_btn_pressed() -> void:
	if game_paused == true:
		return
		
	quit_game_btn()
	
@rpc("any_peer", "call_remote", "reliable")
func announce_disconnected_player():
	opposite_player_disconnected = true
	
func reset_all_variables():
	bot_turn = 0
	player_choser.hide()
	pause_btn.show()
	opposite_player_disconnected = false
	winning_panel.hide()
	disconnected_lbl.hide()
	disconnected_lbl.text = ""
	replay_btn.show()
	replay_btn.text = "PLAY AGAIN"
	win_quit_game_btn.show()
	win_quit_game_btn.text = "QUIT GAME"
	pause_panel.hide()
	pause_btn.icon = load("res://Graphics/general_icons/pause_icon.png")
	holes_used_in_first_stage = []
	holes_used_in_first_stage_bot = []
	plr_1_stones_lbl.text = "0"
	plr_2_stones_lbl.text = "0"
	replay_agreement = [false, false]
	for i in range(1, 11):
		game_holes[i].text = "10"
	game_state = {1: 10, 2: 10, 3: 10, 4: 10, 5: 10, 6: 10, 7: 10, 8: 10, 9: 10, 10: 10, "turn": 0, "player_1_stones": 0, "player_2_stones": 0, "game_turn": 1,}
	is_pausing_game = false
	game_paused = false
	if not going_to_replay:
		Global.players = []
	going_to_replay = false
	Global.after_leaving_a_game()

func _on_peer_disconnected(id : int) -> void:
	replay_agreement[1] = false
	plr_disconnected_index = 1
	opposite_player_disconnected = true
	
func _on_server_disconnected():
	replay_agreement[0] = false
	plr_disconnected_index = 0
	opposite_player_disconnected = true
	

func go_to_player_disconnected_announce():
	if opposite_player_disconnected == false:
		return
	disconnected_lbl.show()
	disconnected_lbl.text = Global.players[plr_disconnected_index] + " disconnected."


func _on_win_quit_game_btn_pressed() -> void:
	quit_game_btn()


func _on_replay_btn_pressed() -> void:
	if opposite_player_disconnected and replay_agreement[is_the_host()] == false:
		return
	
	#IF BOTH PLAYERS WANT TO PLAY AGAIN, THIS BUTTON SERVES NO PURPOSE
	if replay_agreement == [true, true]:
		return
		
	if Global.game_mode == 1:
		win_quit_game_btn.hide()
		replay_agreement = [true, true]
		replay_btn.text = "STARTING NEW MATCH..."
		await get_tree().create_timer(2.0).timeout
		going_to_replay = true
		reset_all_variables()
		set_up()
		return
		
	
	win_quit_game_btn.hide()
	if replay_agreement[is_the_host()] == false:
		replay_agreement[is_the_host()] = true
		replay_btn.text = "CANCEL REQUEST"
		send_replay_request.rpc(is_the_host(), true)
		disconnected_lbl.show()
		disconnected_lbl.text = "Waiting for " + Global.players[opp_plr(is_the_host())] + "..."
		win_quit_game_btn.hide()
	else:
		win_quit_game_btn.show()
		
		#IF DISCONNECTED, THEN DO NOT HIDE THE LABEL
		if not opposite_player_disconnected:
			disconnected_lbl.hide()
			disconnected_lbl.text = ""
			
		replay_btn.text = "PLAY AGAIN"
		replay_agreement[is_the_host()] = false
		send_replay_request.rpc(is_the_host(), false)
	
@rpc("any_peer", "call_remote", "reliable")
func send_replay_request(player_requesting : int, play_again : bool):
	if play_again:
		
		replay_agreement[player_requesting] = true
		if replay_agreement == [true, true]:
			disconnected_lbl.text = Global.players[player_requesting] + " wants to play again."
			before_new_match.rpc()
			return
			
		disconnected_lbl.show()
		disconnected_lbl.text = Global.players[player_requesting] + " wants to play again."
	else:
		replay_agreement[player_requesting] = false
		disconnected_lbl.show()
		disconnected_lbl.text = Global.players[player_requesting] + " canceled their request."

@rpc("any_peer", "call_local", "reliable")
func before_new_match():
	replay_btn.text = "STARTING NEW MATCH..."
	await get_tree().create_timer(2.0).timeout
	
	if opposite_player_disconnected:
		replay_btn.text = "PLAY AGAIN"
		win_quit_game_btn.show()
		disconnected_lbl.show()
		disconnected_lbl.text = Global.players[plr_disconnected_index] + " disconnected."
		replay_agreement = [false, false]
		return
		
	going_to_replay = true
	reset_all_variables()
	set_up()
	
#---------------------BOT FUNCTIONS----------------------

func _on_bot_btn_pressed() -> void:
	bot_turn = 0
	set_up_first_game_turn_bot(bot_turn)


func _on_randomize_plr_btn_pressed() -> void:
	var choices = [0, 1]
	choices.shuffle()
	
	bot_turn = choices[0]
	set_up_first_game_turn_bot(bot_turn)


func _on_plr_chosen_btn_pressed() -> void:
	bot_turn = 1
	set_up_first_game_turn_bot(bot_turn)
	
func set_up_first_game_turn_bot(turn : int):
	player_choser.hide()
	if bot_turn == 0:
		message_label.text = "It's the BOT's turn!"
		bot_move()
	else:
		message_label.text = "It's " + Global.player_name + "'s turn!"
	game_paused = false
	game_resumed.emit()
	
func return_player_or_bot_str(plr : int, is_capitalized : bool) -> String:
	if plr == 0:
		return Global.player_name
	else:
		if is_capitalized:
			return "The BOT"
		else:
			return "the BOT"

func return_player_or_bot_turn() -> int:
	if game_state["turn"] == 0 and bot_turn == 0:
		return 1
	if game_state["turn"] == 1 and bot_turn == 1:
		return 1
	if game_state["turn"] == 0 and bot_turn == 1:
		return 0
	if game_state["turn"] == 1 and bot_turn == 0:
		return 0
	else:
		return 0
		
func opposite_turn_for_bot_mode() -> int:
	var current_plr = 0
	
	if game_state["turn"] == 0 and bot_turn == 0:
		current_plr = 1
	if game_state["turn"] == 1 and bot_turn == 1:
		current_plr = 1
	if game_state["turn"] == 0 and bot_turn == 1:
		current_plr = 0
	if game_state["turn"] == 1 and bot_turn == 0:
		current_plr = 0
		
	return opp_plr(current_plr)

func return_bot_index_from_one_to_two(plr):
	if plr == 0: # the player
		return 1
	else: #the bot
		return 2
			
func end_game_bot():
	
	message_label.text = return_player_or_bot_str(opposite_turn_for_bot_mode(), true) + " has no legal moves left!"
	await get_tree().create_timer(2.0).timeout
	# CHECK IF DRAW
	if game_state["player_" + str(return_bot_index_from_one_to_two(opposite_turn_for_bot_mode())) + "_stones"] >= calculate_stones_left_bot():
		modulate_player_boat_bot(0) #highlight the boat
		
		message_label.text = "But they have enough stones to refill all of their holes!"
			
		
		await refill_time() #refill all holes back
		
		modulate_player_boat_bot(1)
		
		message_label.text = "The game ends in a draw!"
		
		await get_tree().create_timer(2.0).timeout
		end_the_game_and_enter_end_screen(2) #0 host wins, 1 client wins, 2 draw
	else:
		message_label.text = "They do not have enough stones to refill all of their holes!"
		await get_tree().create_timer(2.0).timeout
		message_label.text = return_player_or_bot_str(return_player_or_bot_turn(), true) + " wins the game!"
		await get_tree().create_timer(2.0).timeout
		end_the_game_and_enter_end_screen(game_state["turn"])

func modulate_player_boat_bot(on_or_off):
	if on_or_off == 0: #if 0, modulate!
		if game_state["turn"] == 0:
			if bot_turn == 0:
				plr_1_stones_bg.self_modulate.a = 0.5
			else:
				plr_2_stones_bg.self_modulate.a = 0.5
		else:
			if bot_turn == 0:
				plr_2_stones_bg.self_modulate.a = 0.5
			else:
				plr_1_stones_bg.self_modulate.a = 0.5
	else: #if not, then un-modulate.
		if game_state["turn"] == 0:
			if bot_turn == 0:
				plr_1_stones_bg.self_modulate.a = 1
			else:
				plr_2_stones_bg.self_modulate.a = 1
		else:
			if bot_turn == 0:
				plr_2_stones_bg.self_modulate.a = 1
			else:
				plr_1_stones_bg.self_modulate.a = 1

func bot_move():
	var simulated_game_state = game_state.duplicate()
	var chosen_index = 1
	var move_outcomes = [0.0, 0.0, 0.0, 0.0, 0.0]
	
	if game_state["game_turn"] > 10:
		holes_used_in_first_stage_bot = []
	
	for i in range(1, 6):
		if game_state[5 + i] > 1 and not (i in holes_used_in_first_stage_bot): 
			move_outcomes[i - 1] = evaluate_bot_move(5 + i, simulated_game_state)
		
	#CHOSE THE MOVE
	if game_state["game_turn"] <= 10:
		holes_used_in_first_stage_bot.append(chosen_index)
		
	await get_tree().create_timer(bot_wait_time).timeout
	
	if game_paused:
		await game_resumed
		
	perform_move(2, 1)
	
func evaluate_bot_move(move_index, game_simulaton) -> float:
	var previous_simulation = game_simulaton.duplicate()
	var my_simulation = game_simulaton.duplicate()
	var removed_stones = game_simulaton[move_index] - 1
	var my_simulation_last_hole_played
	
	my_simulation[move_index] = 1
	for i in range(1, removed_stones + 1):
		my_simulation[return_bot_hole_cycle(move_index + i)] += 1
		if i == removed_stones:
			my_simulation_last_hole_played = return_bot_hole_cycle(move_index + i)
			
	var can_capture = true
	var capture_i = 1
	while can_capture:
		if my_simulation[return_bot_hole_cycle(my_simulation_last_hole_played + capture_i)] in [1, 3, 5] and game_state["game_turn"] != 1:
			my_simulation["player_2_stones"] += my_simulation[return_bot_hole_cycle(my_simulation_last_hole_played + capture_i)]
			my_simulation[return_bot_hole_cycle(my_simulation_last_hole_played + capture_i)] = 0
			capture_i += 1
		else:
			can_capture = false
	
	prints(my_simulation, previous_simulation, move_index)
	#DONE!!!, NOW, LET'S EVALUATE:
	
		
	return 0.0

func return_bot_hole_cycle(num : int) -> int:
	if (num % 10) == 0:
		return 10
	else:
		return num % 10

func calculate_stones_left_bot():
	
	var stones_remaining : int = 0
	if game_state["turn"] == 0: 
		if bot_turn == 0: #Calculate the player's balls
			for i in range(1, 6):
				stones_remaining += game_state[i]
				
		else: #calculate the bot's balls
			for i in range(6, 11):
				stones_remaining += game_state[i]
	else: 
		if bot_turn == 0: #Calculate the bot's balls
			for i in range(6, 11):
				stones_remaining += game_state[i]
				
		else: #Calculate the player's balls
			for i in range(1, 6):
				stones_remaining += game_state[i]
				
	return (50 - stones_remaining)

func resign_signal_bot():
	game_paused = true
	message_label.text = Global.player_name + " wants to resign!"
	await get_tree().create_timer(2.0).timeout
	message_label.text = "The BOT wins the game!"
	await get_tree().create_timer(2.0).timeout
	pause_panel.hide()
	pause_btn.hide()
	winning_panel.show()
	winning_lbl.text = "THE BOT WINS!"
	winning_lbl.add_theme_color_override("font_color", Color(modulate_color_2))
