extends Area2D
@export var SPEED = 1 
var move = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if move:
		global_position = lerp(global_position, get_global_mouse_position(),SPEED*delta)

	
	pass
