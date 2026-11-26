extends Control


const PORT = 8910
const MAX_CLIENTS = 2

var peer = ENetMultiplayerPeer.new()

var leave_room : bool = false
var is_connecting : bool = false
var connected_to_room : bool = false

@onready var go_back_btn = $VBoxContainer/go_back_btn
@onready var join_button : Button = $VBoxContainer/room_container/join_button
@onready var ip_input : LineEdit = $VBoxContainer/ip_input
@onready var host_button : Button = $VBoxContainer/room_container/host_button
@onready var status_label : Label = $VBoxContainer/status_label
@onready var start_game_btn : Button = $VBoxContainer/start_game_btn/start_game_button

func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func _process(delta: float) -> void:
	pass
	
func _on_host_button_pressed() -> void:
	if is_connecting:
		multiplayer.multiplayer_peer = null
		is_connecting = false
		for child in go_back_btn.get_children():
			child.show()
		host_button.text = "Host Room"
		status_label.text = "Connection cancelled!"
		join_button.show()
		return
		
	if connected_to_room:
		leave_current_room()
		return
		
		
	if leave_room == true:
		leave_room = false
		for child in go_back_btn.get_children():
			child.show()
		host_button.text = "Host Room"
		status_label.text = "Not Connected"
		join_button.show()
		multiplayer.multiplayer_peer = null
		return
		
	peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		status_label.text = "Failed to create room!"
		return
		
	multiplayer.multiplayer_peer = peer
	
	for child in go_back_btn.get_children():
		child.hide()
		
	status_label.text = "Hosting room!"
	join_button.hide()
	host_button.text = "Leave Room"
	leave_room = true
	Global.players[0] = Global.player_name
	Global.players_game_modes[0] = Global.playing_game


func _on_join_button_pressed() -> void:
	var ip = ip_input.text
	
	peer = ENetMultiplayerPeer.new()
	
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		status_label.text = 'Failed to join room!'
		return
		
	is_connecting = true
	for child in go_back_btn.get_children():
		child.hide()
	host_button.text = "Cancel Connection"
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting..."
	join_button.hide()
	
func _on_connected_to_server():
	connected_to_room = true
	is_connecting = false
	host_button.text = "Leave Room"
	status_label.text = "Successfully connected!"
	register_player.rpc(Global.player_name, Global.playing_game)
	
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name, playing_game):
	var id = multiplayer.get_remote_sender_id()
	Global.players[1] = player_name
	
	Global.players_game_modes[1] = playing_game
	status_label.text = player_name + " joined the room!"
	

func _on_connection_failed():
	is_connecting = false
	multiplayer.multiplayer_peer = null
	host_button.text = "Host Room"
	status_label.text = "Connection failed!"
	join_button.show()
	
func _on_peer_connected(id : int):
	if multiplayer.is_server():
		connected_to_room = true
		appear_button_to_play_game()
		
	
func _on_peer_disconnected(id : int):
	start_game_btn.hide()
	status_label.text = Global.players[1] + " disconnected!"
	Global.players[1] = ""
	connected_to_room = false
	

func appear_button_to_play_game():
	start_game_btn.show()

@rpc("any_peer", "call_local", "reliable")
func uncompatible_games():
	status_label.text = "Cannot start game: incompatible games selected."
	
func _on_start_game_button_pressed() -> void:
	if Global.players_game_modes[0] != Global.players_game_modes[1]: #IF SELECTED DIFFERENT GAMES, DO NOT START
		uncompatible_games.rpc()
		return
	
	update_global_player_array.rpc(Global.players, Global.players_game_modes)
	begin_game.rpc(Global.playing_game)

@rpc("any_peer", "call_local", "reliable")
func begin_game(playing_game_index):
	if playing_game_index == 1: #ADJIBOTO
		get_tree().change_scene_to_file("res://Scenes/adjiboto_room.tscn")
	if playing_game_index == 2: #BUL
		get_tree().change_scene_to_file("res://Scenes/bul_room.tscn")
		
@rpc("any_peer", "call_local", "reliable")
func update_global_player_array(player_array, player_game_modes):
	Global.players = player_array
	Global.players_game_modes = player_game_modes
	
func _on_server_disconnected():
	leave_current_room()
	connected_to_room = false
	status_label.text = "Host disconnected!"

func leave_current_room():
	if peer:
		peer.close()
		
	multiplayer.multiplayer_peer = null

	
	leave_room = false
	is_connecting = false
	connected_to_room = false
	
	Global.players.clear()
	
	host_button.text = "Host Room"
	status_label.text = "Not Connected"
	
	join_button.show()
	start_game_btn.hide()
	
	for child in go_back_btn.get_children():
		child.show()


func _on_go_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/choosing_game_mode.tscn")
