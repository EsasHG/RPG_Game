extends Area2D

@export var BASE_SPEED = 10 
@export var ACCELERATION = 5

var speed = BASE_SPEED
@onready var target = get_tree().get_nodes_in_group("PlayerCharacters").pick_random()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#target = get_tree().get_nodes_in_group("PlayerCharacters").pick_random()
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(5,5), 2)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if(!target)
		
	var direction = target.global_position - global_position
	global_position = global_position + direction.normalized() * speed * delta
	speed += ACCELERATION
	pass


func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if(area.is_in_group("PlayerCharacters")):
		print_debug("Projectile hit player!")
		area.damage(1)
		queue_free()
	pass # Replace with function body.
