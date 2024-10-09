extends Node2D

class_name BattleManager 
signal player_changed(player: Area2D)
signal all_players_done
#hva om man kan ha flere synergies på samme attack???? holy trinity:
#Horizontal, vertical og diagonal gjør høyere damage der de treffer, men gjør også 1 damage inne i trekanten?? 
#eller har en base damage for innsiden, men den fordeles på alle fiender
var activeEffects = [] 
var currentEffect : int = 0
var numTurns = 0
var maxTurns = 3
var encounterNum = 0
@export var encounters :Array[PackedScene] = []
@export var bomb : Attack
@onready var menu_button: MenuButton = $"../GUI/PanelContainer/BattleSelction/MenuButton"

@onready var players:Array[Area2D] = [find_child("Bill"), find_child("James"), find_child("Proton")]
@onready var menu: MenuButton = get_parent().find_child("MenuButton")
@onready var itemMenu: MenuButton = get_parent().find_child("ItemButton")
@onready var turnLabel: Label = get_parent().find_child("TurnLabel")
var currentPlayer : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child.call_deferred(encounter)
	#menu.get_popup().id_pressed.connect(_on_attack_selected.bind())
	get_window().grab_focus()
	menu.grab_focus()
	itemMenu.get_popup().clear()
	itemMenu.get_popup().add_item("Bomb")
	itemMenu.get_popup().id_pressed.connect(_on_item_selected.bind())
	reset_attacks()
	player_changed.emit(players[currentPlayer])


func reset_attacks():
	menu.get_popup().clear()
	for attack in players[currentPlayer].attacks:
		menu.get_popup().add_item(attack.name)


func attack_pressed():
	if(currentEffect < activeEffects.size()):
		if("move" in activeEffects[currentEffect]):
			activeEffects[currentEffect].move = false
		currentEffect+=1
		var hitEnemies = []
		if(currentEffect >= activeEffects.size()):
			for attack in activeEffects:
				for area in attack.get_overlapping_areas():
					if(area.is_in_group("Enemies")):
						area.pre_damage()
						hitEnemies.append(area)
			currentEffect = 0
			numTurns = 0
			
			var tween = get_tree().create_tween()
			for attack in activeEffects:
				#tween.parallel()
				tween.set_ease(Tween.EASE_IN)
				tween.tween_property(attack.get_child(1),"modulate:a",1,0.2)
				tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
				tween.tween_property(attack.get_child(1), "modulate", Color.TRANSPARENT, 0.3)
				tween.tween_callback(attack.queue_free)
			tween.tween_callback(end_attack.bind(hitEnemies))
				
#			get_tree().create_timer(1.5,).connect("timeout", enemiesAttack)
		else:
			do_attacks()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if(Input.is_action_just_pressed("Space")):
		attack_pressed()


func end_attack(hitEnemies :Array):
	activeEffects.clear()
	for enemy in hitEnemies:
		enemy.damage(1)
	enemiesAttack()
#	get_tree().create_timer(1.5,).connect("timeout", enemiesAttack)


func enemiesAttack():
	print_debug("Enemies Attack!")
	
	if(get_tree().get_node_count_in_group("Enemies") == 0):
		turnLabel.text = "You won!"
		encounterNum+=1
		print_debug("loading next encounter!")
		
		load_encounter()
	else:
		turnLabel.text =  "Enemy turn"
		var enemies = get_tree().get_nodes_in_group("Enemies")		for enemy in enemies:
			enemy.attack_projectile()


func _on_item_selected(id: int):
	if(id == 0):
		var atk = bomb.scene.instantiate()
		activeEffects.push_back(atk)
		
	numTurns+=1
	end_turn()


func end_turn():
	if( numTurns >= maxTurns):
		do_attacks()
	currentPlayer+=1
	if(currentPlayer >= players.size()):
		currentPlayer = 0
		all_players_done.emit()
	else:
		player_changed.emit(players[currentPlayer])
	reset_attacks()


func do_attacks():
	if(activeEffects.is_empty()):
		return
	print_debug("Running attacks!")
	if(currentEffect < activeEffects.size()):
		get_tree().root.add_child.call_deferred(activeEffects[currentEffect])


func load_encounter():
	if(encounterNum >=encounters.size()):
		encounterNum=0
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child(encounter)


func _on_attack_selected(atk: Attack) -> void:
	print_debug("Attack selected")
	var activeAtk = atk.scene.instantiate()
	activeEffects.push_back(activeAtk)
	numTurns+=1
	end_turn()


func _on_attack_pressed() -> void:
	attack_pressed()
