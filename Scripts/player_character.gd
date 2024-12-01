extends Area2D
class_name PlayerCharacter
signal health_changed(newHealth:int)

var max_health : int  = 10
var current_health : int  = 10

@export var attacks :Array[Attack] = [] 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func damage(dmg : int):
	current_health-=dmg 
	
	if(current_health > max_health):
		current_health = max_health
	elif current_health < 0:
		current_health = 0
	
	health_changed.emit(current_health)
	#healthChanged()
	
