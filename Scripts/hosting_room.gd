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
	Global.players.append(Global.player_name)


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
	register_player.rpc_id(1, Global.player_name)
	
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name):
	var id = multiplayer.get_remote_sender_id()
	Global.players.append(player_name)
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
	if Global.players.size() > 1:
		status_label.text = Global.players[1] + " disconnected!"
		Global.players.pop_back()
	connected_to_room = false
	

func appear_button_to_play_game():
	start_game_btn.show()


func _on_start_game_button_pressed() -> void:
	print("START BUTTON PRESSED")
	print("Multiplayer peer: ", multiplayer.multiplayer_peer)
	print("Is connected: ", multiplayer.multiplayer_peer.get_connection_status())
	
	update_global_player_array.rpc(Global.players)
	begin_game.rpc(Global.playing_game)

@rpc("any_peer", "call_local", "reliable")
func begin_game(playing_game_index):
	if playing_game_index == 1: #ADJIBOTO
		get_tree().change_scene_to_file("res://Scenes/adjiboto_room.tscn")
		
@rpc("any_peer", "call_local", "reliable")
func update_global_player_array(player_array):
	Global.players = player_array
	
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
