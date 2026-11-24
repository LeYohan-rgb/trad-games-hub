extends Node

var player_name : String = "Player 1"
var game_mode : int = 0 #O IS ONLINE, 1 IS BOT
var playing_game : int = 0
var players :Array[String] = []
var is_debugging : bool = true #ORIGIANL PROPORTION WAS 720 X 1280

var game_names : Dictionary = {
	1: "Adjiboto",
}
var game_rules : Dictionary = {
	1: "Adjiboto is a charming game.",
}

var game_history : Dictionary = {
	1: "Adjiboto was seen in Guyana.",
}
#1 - ADJIBOTO
func after_leaving_a_game():
	playing_game = 0
	
