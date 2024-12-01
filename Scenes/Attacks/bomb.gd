extends Area2D
@export var SPEED = 1000
var move = true
var time: int = 3
var tween :Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween = get_tree().create_tween()
	tween.tween_property($Label, "theme_override_colors/font_color", Color.TRANSPARENT, 1.0)
	tween.tween_callback(countdown)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if move:
		#global_position = lerp(global_position, get_global_mouse_position(),SPEED*delta)
		var dir: Vector2 = Vector2(0,0)
	
		if(Input.is_action_pressed("ui_left")):
			dir.x-=1
		if(Input.is_action_pressed("ui_right")):
			dir.x+=1
			
		if(Input.is_action_pressed("ui_up")):
			dir.y-=1
		if(Input.is_action_pressed("ui_down")):
			dir.y+=1
			
		global_position = global_position + dir.normalized()*SPEED*delta

func countdown():
	time-=1
	if(time > 0):
		$Label.add_theme_color_override("font_color",Color.BLACK)
		$Label.text = str(time)
		
		tween = get_tree().create_tween()
		
		tween.tween_property($Label, "theme_override_colors/font_color", Color.TRANSPARENT, 1.0)
		tween.tween_callback(countdown)
	elif(move):
		
		var b  = get_tree().root.find_child("GUI", true, false)
		b._on_attack_placed() 
		

func on_placed():
	move = false
	tween.stop()
	$Label.text = ""
	$Label.queue_free()
	pass
