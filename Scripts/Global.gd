extends Node

var player_name : String = "Player 1"
var game_mode : int = 0 #O IS ONLINE, 1 IS BOT
var playing_game : int = 0
var players :Array[String] = []
var is_debugging : bool = false #ORIGIANL PROPORTION WAS 720 X 1280


#1 - ADJIBOTO
func after_leaving_a_game():
	playing_game = 0
	
