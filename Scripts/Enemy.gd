extends Area2D

class_name Enemy
var projectile = preload("res://Scenes/projectile.tscn")
@export var health = 1
var hitCount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if(has_node("ProgressBar")):
		$ProgressBar.max_value = health
		$ProgressBar.value = health
	
	add_to_group("Enemies")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
	
func attack_projectile():
	if(health > 0):
		var proj = projectile.instantiate()
		proj.global_position = global_position
		get_tree().root.add_child(proj)
		
func damage(dmg : int):
	if(hitCount >= 2):
		dmg*= 5*hitCount
		
	health-= dmg
	
	if($ProgressBar):
		$ProgressBar.value = health
	
	
	if(health <= 0):
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property($Sprite2D, "modulate", Color.TRANSPARENT, 1)
		tween.tween_callback(queue_free)
	else:
		hitCount = 0
		
func pre_damage():
	hitCount+=1
