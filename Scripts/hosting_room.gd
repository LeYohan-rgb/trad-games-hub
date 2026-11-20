extends Control


const PORT = 8910
const MAX_CLIENTS = 2

var peer = ENetMultiplayerPeer.new()

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
	
func _on_host_button_pressed() -> void:
	var error = peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		status_label.text = "Failed to create room!"
		return
		
	multiplayer.multiplayer_peer = peer
	
	status_label.text = "Hosting room!"
	Global.players.append(Global.player_name)


func _on_join_button_pressed() -> void:
	var ip = ip_input.text
	
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		status_label.text = 'Failed to join room!'
		return
		
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connecting..."
	
func _on_connected_to_server():
	status_label.text = "Successfully connected!"
	register_player.rpc_id(1, Global.player_name)
	
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name):
	var id = multiplayer.get_remote_sender_id()
	Global.players.append(player_name)
	status_label.text = player_name + " joined the room!"
	

func _on_connection_failed():
	status_label.text = "Connection failed!"
	
func _on_peer_connected(id : int):
	if multiplayer.is_server():
		appear_button_to_play_game()
		
	print("Player connected! ID: ", id)
	
func _on_peer_disconnected(id : int):
	print("Player disconnected! ID: ", id)
	

func appear_button_to_play_game():
	start_game_btn.show()


func _on_start_game_button_pressed() -> void:
	update_global_player_array.rpc(Global.players)
	begin_game.rpc(Global.playing_game)

@rpc("any_peer", "call_local", "reliable")
func begin_game(playing_game_index):
	if playing_game_index == 1: #ADJIBOTO
		get_tree().change_scene_to_file("res://Scenes/adjiboto_room.tscn")
		
@rpc("any_peer", "call_local", "reliable")
func update_global_player_array(player_array):
	Global.players = player_array
