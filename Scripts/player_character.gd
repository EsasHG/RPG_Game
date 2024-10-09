extends Area2D

@export var infoContainer : VBoxContainer

@export var max_health : int  = 10
@export var current_health : int  = 10

@export var attacks :Array[Attack] = [] 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	infoContainer.get_node("Name").text = name
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func damage(dmg : int):
	current_health-=dmg 
	infoContainer.get_node("CharacterHealth").text = "HP: " + str(current_health) + "/" +  str(max_health)
	if(current_health <= 0):
		die()
		
func die():
	pass
