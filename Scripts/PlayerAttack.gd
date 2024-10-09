extends Area2D

@export var SPEED = 1400

var dir = 1
@export var horizontal = true
var move = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (move):
		if(horizontal):
			position.y = position.y + dir * delta * SPEED
		else:
			position.x = position.x + dir * delta * SPEED

func _on_area_exited(area: Area2D) -> void:
	if(area.name == "BattleArea"):
		dir*=-1
