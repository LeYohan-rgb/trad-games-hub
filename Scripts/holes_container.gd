extends GridContainer

signal performed_move_on_hole(hole_num)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_btn_1_1_pressed() -> void:
	selected_hole(1)


func _on_btn_1_2_pressed() -> void:
	selected_hole(2)


func _on_btn_1_3_pressed() -> void:
	selected_hole(3)


func _on_btn_1_4_pressed() -> void:
	selected_hole(4)


func _on_btn_1_5_pressed() -> void:
	selected_hole(5)

func selected_hole(hole_num):
	performed_move_on_hole.emit(hole_num)
