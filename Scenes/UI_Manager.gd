extends Control

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

@onready var players:Array[Area2D] = [get_parent().find_child("World").find_child("Bill"), get_parent().find_child("World").find_child("James"), get_parent().find_child("World").find_child("Proton")]
#@onready var players:Array[Area2D] = [get_tree().root.find_child("Bill"), get_tree().root.find_child("James"), get_tree().root.find_child("Proton")]
@onready var menu: MenuButton = get_parent().find_child("MenuButton")
@onready var itemMenu: MenuButton = get_parent().find_child("ItemButton")
@onready var turnLabel: Label = get_parent().find_child("TurnLabel")
var currentPlayer : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PanelContainer/BattleSelction/Fight.grab_focus()
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child.call_deferred(encounter)
	#menu.get_popup().id_pressed.connect(_on_attack_selected.bind())
	get_window().grab_focus()
	
	var itemLabel = Label.new()
	itemLabel.text = "Items:"
	$ItemContainer/ItemList.add_child(itemLabel)
	var itemButton: Button = Button.new()
	itemButton.focus_mode = Control.FOCUS_ALL
	itemButton.text = "Bomb"
	$ItemContainer/ItemList.add_child(itemButton)
	itemButton.connect("pressed", _on_attack_selected.bind(bomb))

	reset_attacks()
	change_player(players[currentPlayer])

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
		start_attack()
	else:
		change_player(players[currentPlayer])
	reset_attacks()


func reset_attacks():
	if(players.size() == 0):
		players = [ get_parent().find_child("World").find_child("Bill"), get_parent().find_child("World").find_child("James"), get_parent().find_child("World").find_child("Proton")]
		
	#for attack in players[currentPlayer].attacks:
		#menu.get_popup().add_item(attack.name)


func load_encounter():
	if(encounterNum >=encounters.size()):
		encounterNum=0
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child(encounter)


func do_attacks():
	if(activeEffects.is_empty()):
		return
	print_debug("Running attacks!")
	if(currentEffect < activeEffects.size()):
		get_tree().root.add_child.call_deferred(activeEffects[currentEffect])


func _on_fight_pressed() -> void:
	$PanelContainer/BattleSelction/Fight.disabled = true
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = true
	$AttackContainer.show()
	$AttackContainer/AttackList.get_child(1).grab_focus()


func _on_items_pressed() -> void:
	$PanelContainer/BattleSelction/Fight.disabled = true
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = true
	$ItemContainer.show()
	$ItemContainer/ItemList.get_child(1).grab_focus()


func _on_attack_selected(atk: Attack) -> void:
	print_debug("Attack selected")
	var activeAtk = atk.scene.instantiate()
	activeEffects.push_back(activeAtk)
	numTurns+=1
	end_turn()

func change_player(player: Area2D):
	print_debug("Player Changed!")
	var children = $AttackContainer/AttackList.get_children()
	for child in children:
		child.call_deferred("free")
	var attackLabel = Label.new()
	attackLabel.text = player.name + "'s attacks:"
	$AttackContainer/AttackList.add_child(attackLabel)
	for i: int in  player.attacks.size():
		var attackButton: Button = Button.new()
		attackButton.focus_mode = Control.FOCUS_ALL
		attackButton.text = player.attacks[i].name
		$AttackContainer/AttackList.add_child(attackButton)
		attackButton.connect("pressed",  _on_attack_selected.bind(player.attacks[i]))
		
	$PanelContainer3/TurnLabel.text = player.name + "'s Turn"
	
	$AttackContainer.hide()
	$ItemContainer.hide()
		
	$PanelContainer/BattleSelction/Fight.disabled = false
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = false
	$PanelContainer/BattleSelction/Fight.grab_focus()


func start_attack() -> void:
	$PanelContainer3/TurnLabel.text = "Commence attack!"
	$AttackContainer.hide()
	$ItemContainer.hide()
	$PanelContainer5.show()
	$PanelContainer5/Attack.grab_focus()

func _on_attack_pressed() -> void:
	if(currentEffect < activeEffects.size()):
		if("move" in activeEffects[currentEffect]):
			activeEffects[currentEffect].move = false
		currentEffect+=1
		var hitEnemies = []
		if(currentEffect >= activeEffects.size()):
			$PanelContainer5.hide()
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

func end_attack(hitEnemies :Array):
	activeEffects.clear()
	for enemy in hitEnemies:
		enemy.damage(1)
	#enemiesAttack()
	get_tree().create_timer(1.5,).connect("timeout", enemiesAttack)

func enemiesAttack():
	print_debug("Enemies Attack!")
	
	var timer: SceneTreeTimer = get_tree().create_timer(2)
	timer.timeout.connect(change_player.bind(players[currentPlayer]))
	if(get_tree().get_node_count_in_group("Enemies") == 0):
		turnLabel.text = "You won!"
		encounterNum+=1
		print_debug("loading next encounter!")
		#load_encounter()
		timer.timeout.connect(load_encounter)
	else:
		turnLabel.text =  "Enemy turn"
		var enemies = get_tree().get_nodes_in_group("Enemies")
		for enemy in enemies:
			enemy.attack_projectile()
			
		
