extends Node

var player_name : String = "Player 1"
var game_mode : int = 0 #O IS ONLINE, 1 IS BOT
var playing_game : int = 0
var players :Array[String] = ["", ""]
var players_game_modes : Array = [0, 0]
var is_debugging : bool = false #ORIGIANL PROPORTION WAS 720 X 1280

var list_of_available_games = [
	"Adjiboto",
	"Bul"
]

var game_dictionary : Dictionary = {
	"Adjiboto" : {
		"period": ["Modern"],
		"region": ["America"],
		"category": ["Board", "Sow", "Two rows"],
	},
	"Bul" : {
		"period": ["Modern"],
		"region": ["America"],
		"category": ["Board", "War", "Replacement", "Eliminate", "All"],
	},
}

var period_index : Dictionary = {
	1: "Ancient",
	2: "Medieval",
	3: "Modern"
}

var region_index : Dictionary = {
	1: "Africa",
	2: "America",
	3: "Asia",
	4: "Australia and NZ",
	5: "Caribbean",
	6: "Europe",
	7: "Melanesia",
	8: "Micronesia",
	9: "Polynesia"
}

var category_index : Dictionary = {
	1: "Board",
	2: "Hunt",
	3: "Race",
	4: "Sow",
	5: "Space",
	6: "War",
	7: "Math",
	8: "Puzzle",
	9: "Reconstruction"
}

var game_names : Dictionary = {
	1: "Adjiboto",
	2: "Bul",
}

var game_rules : Dictionary = {
	1: "It is played on a 2x5 board with 10 stones in each hole. Each player has a store called boto at their right hand and five corresponding holes in front of them.

It is only permitted to play a hole with at least two stones.

Each turn a player distributes the contents of one of their five holes, except one stone that remains inside, one by one, in consecutive holes in an anti-clockwise direction.

If the last stone ends in a hole preceding a hole containing one, three, or five stones, these stones are captured and put into the player's boto. Any subsequent holes also containing one, three, or five stones are captured, until a hole is reached that does not have one of these numbers of stones. The exception to this is in the first move when no captures are made.

OPENING PHASE:
In the first ten turns, each player must play each of their five holes in any order.

WINNING CONDITION:
A player wins when their opponent can no longer play on their turn (none of their holes has more than one stone). However, if the opponent can refill all of their holes with ten stones with the stones they have captured, the game ends in a draw. (For example, if an opponent has captured 45 stones and each of their holes has one stone each, the game ends in a draw).
",
2: "Idk"
}

var game_history : Dictionary = {
	1: "Adjiboto ('pebble boat') is a mancala-style game played by the Saramaccans, a tribe of Bush-Negroes formed by escaped slaves, who live in the upper Saramacca river in Surinam. The game was first observed in the early twentieth century in Beidotti village, and it resembles mancala games known in Benin, West Africa.

The game is used to entertain the dead during the ten-day period preceding burial in the kre wosu, or house of mourning. The play is only carried out during the daylight hours because in the night the yorkas, or ghosts of the dead, would come and eventually carry away spritis.

The boards are only carved by old widowed men. They are made in two shapes, those having straight tops, and those in which the tops are curved. A village should have both types, so that if a person was fond of one kind of board dies, the people can play for a time on the other and there will be a lessened danger of his ghost coming to play with them. Although the Bush-Negroes are fine wood-carvers, the Saramacca boards are of the roughest. This is because of the sacred character of the game which is not one which can be hurried in playing. It must entail some effort and even pain to bring it to perfection.

REFERENCE FOR THE GAME RULES:
90. Adjiboto, an African Game of the Bush-Negroes of Dutch Guiana (Melville J. Herskovits, Vol. 29 (Jul., 1929), pp. 122-127)

REFERENCE FOR THE GAME HISTORY:
https://mancala.fandom.com/wiki/Adji-boto",
2: "Idk"
}

#1 - ADJIBOTO
func after_leaving_a_game():
	playing_game = 0
	
