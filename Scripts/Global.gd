extends Node

var player_name : String = "Player 1"
var game_mode : int = 0 #O IS ONLINE
var playing_game : int = 0
var players :Array[String] = []
var is_debugging : bool = false
#1 - ADJIBOTO


func after_leaving_a_game():
	players = []
	playing_game = 0
	
