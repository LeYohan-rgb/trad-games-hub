extends VBoxContainer

var is_showing_desc : bool = false
var game_showing : int = 0
@onready var desc_box = $desc_box
@onready var display_list = $ScrollContainer
@onready var text_lbl = $desc_box/Panel2/text_container/ScrollContainer/text_lbl
@onready var search_section = $VBoxContainer
@onready var title_lbl = $Control/Control2/Label
@onready var game_image = $desc_box/image_panel

#INDEXES
var period_index = 0
var region_index = 0
var category_index = 0 

@onready var game_buttons = {
	"Adjiboto" : $ScrollContainer/display_list/adjiboto_container,
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unshow_desc_box()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	Global.playing_game = 1
	get_tree().change_scene_to_file("res://Scenes/choosing_game_mode.tscn")


func _on_go_back_btn_pressed() -> void:
	if is_showing_desc:
		unshow_desc_box()
	else:
		get_tree().change_scene_to_file("res://Scenes/starting_screen.tscn")


func _on_adjiboto_desc_pressed() -> void:
	game_showing = 1
	show_desc_box(1)
	
func show_desc_box(game_shown : int):
	title_lbl.text = Global.game_names[game_shown]
	is_showing_desc = true
	display_list.hide()
	search_section.hide()
	desc_box.show()
	
	game_image.icon = load("res://Graphics/game_rules_images/"+Global.game_names[game_shown]+".png")
	text_lbl.text = Global.game_rules[game_shown]

func unshow_desc_box():
	title_lbl.text = "Traditional Games List"
	is_showing_desc = false
	display_list.show()
	search_section.show()
	desc_box.hide()


func _on_history_btn_pressed() -> void:
	game_image.icon = load("res://Graphics/history_images/"+Global.game_names[game_showing]+".png")
	text_lbl.text = Global.game_history[game_showing]


func _on_game_rules_btn_pressed() -> void:
	game_image.icon = load("res://Graphics/game_rules_images/"+Global.game_names[game_showing]+".png")
	text_lbl.text = Global.game_rules[game_showing]


func _on_game_search_bar_text_changed(new_text: String) -> void:
	for game in Global.list_of_available_games:
		if game.to_lower().contains(new_text.to_lower()):
			game_buttons[game].show()
		else:
			game_buttons[game].hide()

func _on_period_sort_btn_item_selected(index: int) -> void:
	period_index = index
	sort_everything()
	
func sort_everything():
	
	for game in Global.list_of_available_games:
		game_buttons[game].show()
				
	#PERIOD
	if period_index == 0:
		pass
	else:
		for game in Global.list_of_available_games:
			if Global.period_index[period_index] in Global.game_dictionary[game]["period"]:
				game_buttons[game].show()
			else:
				game_buttons[game].hide()
				
	#REGION
	if region_index == 0:
		pass
	else:
		for game in Global.list_of_available_games:
			if Global.region_index[region_index] in Global.game_dictionary[game]["region"]:
				game_buttons[game].show()
			else:
				game_buttons[game].hide()
				
	#CATEGORY
	if category_index == 0:
		pass
	else:
		for game in Global.list_of_available_games:
			if Global.category_index[category_index] in Global.game_dictionary[game]["category"]:
				game_buttons[game].show()
			else:
				game_buttons[game].hide()
	
func _on_region_sort_btn_item_selected(index: int) -> void:
	region_index = index
	sort_everything()
	
func _on_category_sort_btn_item_selected(index: int) -> void:
	category_index = index
	sort_everything()
