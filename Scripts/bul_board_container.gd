extends VBoxContainer

signal pressed_row(row_pressed)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed(extra_arg_0: int) -> void:
	pressed_row.emit(extra_arg_0)
