extends Control

#hva om man kan ha flere synergies på samme attack???? holy trinity:
#Horizontal, vertical og diagonal gjør høyere damage der de treffer, men gjør også 1 damage inne i trekanten?? 
#eller har en base damage for innsiden, men den fordeles på alle fiender

var activeEffects = [] 
var commands = [] 
var currentEffect : int = 0
var encounterNum = 0

@export var encounters :Array[PackedScene] = []
@export var bomb : Attack
@export var party:Array[Character] = []

@onready var characterBase = preload("res://Scenes/Characters/CharacterBase.tscn")
@onready var characterInfo = preload("res://Scenes/Characters/CharacterInfo.tscn")
@onready var turnLabel: Label = get_parent().find_child("TurnLabel")
@onready var infoBoxes:Array[Node] = []

var inv : Dictionary = {"Bomb":2,"Potion":2, "Revive":1}
@onready var existingItems : Dictionary =  {"Bomb":bomb}

var combatParty:Array[Character] = []
var players: Array[Area2D] = []
var menuHistory: Array[Control] = []
var currentPlayer : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var charOffset : int = 0
	combatParty = party
	
	for i:int in combatParty.size():
		var newChar: PlayerCharacter = characterBase.instantiate()
		var newInfo = characterInfo.instantiate()
		newChar.name = combatParty[i].name
		newChar.current_health = combatParty[i].current_health
		newChar.max_health = combatParty[i].max_health
		newInfo.get_node("Name").text = combatParty[i].name
		newInfo.get_node("CharacterHealth").text = "HP: " + str(combatParty[i].current_health) + "/" +  str(combatParty[i].max_health)
		
		get_parent().get_parent().find_child("World").add_child(newChar)
		find_child("PlayerStatusContainer").add_child(newInfo)
		infoBoxes.push_back(newInfo)
		players.push_back(newChar)
		newChar.position = Vector2(608 + charOffset, 840)
		newChar.health_changed.connect(_on_health_changed.bind(i))
		charOffset+= 357
	
	$PanelContainer/BattleSelction/Fight.grab_focus()
	menuHistory.push_back($PanelContainer/BattleSelction)
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child.call_deferred(encounter)
	get_window().grab_focus()
	
	#setup inventory

	setup_inventory()

	change_player()

func _process(delta: float) -> void:
	if(Input.is_action_just_pressed("ui_cancel")):
		go_back()

func load_encounter():
	if(encounterNum >=encounters.size()):
		encounterNum=0
	var encounter = encounters[encounterNum].instantiate()
	get_tree().root.add_child(encounter)


func setup_inventory():
	
	var children = $ItemContainer/ItemList.get_children()
	for child in children:
		child.call_deferred("free")
		
	for key :String in inv.keys():
		var itemButton: Button = Button.new()
		itemButton.focus_mode = Control.FOCUS_ALL
		
		itemButton.text = key + " x" +  str(inv[key])
		$ItemContainer/ItemList.add_child(itemButton)
		itemButton.connect("pressed", _on_item_selected.bind(key))

func go_back():
	#Going back at top level takes us to previous player
	if(menuHistory.size() == 1):
		if(currentPlayer > 0):
			currentPlayer-=1
			var cmd : Attack = commands.back()
			
			if(inv.has(cmd.name)):
				inv[cmd.name]+=1
				#inventory[0][1]+=1
				setup_inventory()
			elif cmd.name == "Bomb":
				inv[cmd.name]=1
				setup_inventory()
			#if(cmd.name == bomb):
			#	inventory[0][1]+=1
			#	setup_inventory()
			#cmd.queue_free()
			commands.pop_back()
			change_player()
	else:
		ui_go_back()
	
	
func ui_go_back():
	if(menuHistory.size() == 1 or menuHistory.back() == $PanelContainer5):
		return
	print_debug("Going back! ")
	print_debug("Hiding " + menuHistory.back().name + "! ")
	menuHistory.back().get_parent().hide()
	menuHistory.pop_back()	
	menuHistory.back().get_parent().show()
	for child in menuHistory.back().get_children():
		if("disabled" in child):
			child.disabled = false
	menuHistory.back().get_child(0).grab_focus()
	print_debug("New focus: " + menuHistory.back().name)


			
func end_turn():
	
	currentPlayer+=1
	
	if(currentPlayer >= combatParty.size()):
		currentPlayer = 0
		
		show_attack_ui()
		for cmd : Attack in commands:
			var atk = cmd.scene.instantiate()
			activeEffects.push_back(atk)
		start_next_attack()
	else:
		change_player()


func show_attack_ui() -> void:
	$PanelContainer3/TurnLabel.text = "Commence attack!"
	$AttackContainer.hide()
	$ItemContainer.hide()
	menuHistory.pop_back()
	$PanelContainer5.show()
	$PanelContainer5/Attack.grab_focus()
	menuHistory.push_back($PanelContainer5)



func start_next_attack():
	print_debug("Running attacks!")
	if(activeEffects.is_empty()):
		return
	if(currentEffect < activeEffects.size()):
		get_tree().root.add_child.call_deferred(activeEffects[currentEffect])


#Setting all UI ready for current player's turn
func change_player():
	if(combatParty[currentPlayer].current_health <=0):
		combatParty.remove_at(currentPlayer)
		if(combatParty.size() <= 0):
			$PanelContainer3/TurnLabel.text = "YOU LOST!"
		else:
			end_turn()
	
	var children = $AttackContainer/AttackList.get_children()
	for child in children:
		child.call_deferred("free")
	var attackLabel = Label.new()
	attackLabel.text = combatParty[currentPlayer].name + "'s attacks:"
	$AttackContainer/AttackList.add_child(attackLabel)
	for i: int in  combatParty[currentPlayer].attacks.size():
		var attackButton: Button = Button.new()
		attackButton.focus_mode = Control.FOCUS_ALL
		attackButton.text = combatParty[currentPlayer].attacks[i].name
		$AttackContainer/AttackList.add_child(attackButton)
		attackButton.connect("pressed",  _on_attack_selected.bind(combatParty[currentPlayer].attacks[i]))
		
	$PanelContainer3/TurnLabel.text = combatParty[currentPlayer].name + "'s Turn"
	
	ui_go_back()
	
	$PanelContainer/BattleSelction/Fight.disabled = false
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = false
	$PanelContainer/BattleSelction/Fight.grab_focus()


#Deals damage
func end_attack(hitEnemies :Array):
	commands.clear()
	activeEffects.clear()
	for enemy in hitEnemies:
		enemy.damage(1)
	#enemiesAttack()
	get_tree().create_timer(1.5,).connect("timeout", enemiesAttack)

#Enemy's turn
func enemiesAttack():
	print_debug("Enemies Attack!")
	if(get_tree().get_node_count_in_group("Enemies") == 0):
		end_round()
		return
	var timer: SceneTreeTimer = get_tree().create_timer(2)
	timer.timeout.connect(end_round)
	turnLabel.text =  "Enemy turn"
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for enemy in enemies:
		enemy.attack_projectile()

func end_round():
	if(get_tree().get_node_count_in_group("Enemies") == 0):
		turnLabel.text = "You won!"
		encounterNum+=1
		print_debug("loading next encounter!")
		get_tree().create_timer(1.0).timeout.connect(load_encounter)
	var livingPlayer : bool = false
	for i:int in combatParty.size():
		if(party[i].current_health > 0):
			livingPlayer = true
		else:
			combatParty.remove_at(i)
			players[i].remove_from_group("PlayerCharacters")
	if(!livingPlayer):
		turnLabel.text = "You lost!"
	else:
		change_player()

#Setup for attack selection menu
func _on_fight_pressed() -> void:
	$PanelContainer/BattleSelction/Fight.disabled = true
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = true
	$AttackContainer.show()
	$AttackContainer/AttackList.get_child(1).grab_focus()
	menuHistory.push_back($AttackContainer/AttackList)

#Setup for item selection menu
func _on_items_pressed() -> void:
	$PanelContainer/BattleSelction/Fight.disabled = true
	for child : Button in $PanelContainer/BattleSelction.get_children():
		child.disabled = true
	$ItemContainer.show()
	if($ItemContainer/ItemList.get_child_count() >=1):
		$ItemContainer/ItemList.get_child(0).grab_focus()
	else:
		$PanelContainer/BattleSelction/Items.release_focus()
		
	menuHistory.push_back($ItemContainer/ItemList)

#Called when an attack is selected
func _on_attack_selected(atk: Attack) -> void:
	
	commands.push_back(atk)
	#var activeAtk = atk.scene.instantiate()
	#activeEffects.push_back(activeAtk)
	end_turn()


#Called when an item is selected
func _on_item_selected(key: String):
	
	if(key == "Potion" or key == "Revive"):
		for player in players:
			var button: Button = Button.new()
			button.focus_mode = Control.FOCUS_ALL
		
			button.text = player.name
			$UseRecoveryMenu/PlayerList.add_child(button)
			button.connect("pressed", _on_recover_player_selected.bind(player))
		$ItemContainer.hide()
		$UseRecoveryMenu.show()
		$UseRecoveryMenu/PlayerList.get_child(1).grab_focus()
		menuHistory.push_back($UseRecoveryMenu/PlayerList)
		
	else:
		_on_attack_selected(existingItems[key])
		end_turn()
	
	inv[key]-=1
	if(inv[key] <= 0):
		inv.erase(key)
	
	setup_inventory()
	
func _on_recover_player_selected(player: PlayerCharacter):
	
	player.damage(-2)
	player.current_health +=2
	player.health_changed.emit()
	$UseRecoveryMenu.hide()
	menuHistory.pop_back()
	setup_inventory()
	

func _on_attack_placed() -> void:
	if(currentEffect < activeEffects.size()):
		#Places current attack
		
		if(activeEffects[currentEffect].has_method("on_placed")):
			activeEffects[currentEffect].on_placed()
			
		
		if("move" in activeEffects[currentEffect]):
			activeEffects[currentEffect].move = false
		currentEffect+=1
		
		await get_tree().create_timer(0.2).timeout
		
		#Checks if all attacks are placed
		if(currentEffect >= activeEffects.size()):
			activate_attacks()
		else:
			start_next_attack()

func activate_attacks():
	var hitEnemies = []
	$PanelContainer5.hide()
	menuHistory.pop_back()
	for attack: Area2D in activeEffects:
		for area in attack.get_overlapping_areas():
			if(area.is_in_group("Enemies")):
				area.pre_damage()
				hitEnemies.append(area)
		
	#Better solution to above that don't need the timer. 
	#Need to solve the direction problem differently before this can be used
		#var t :ShapeCast2D = attack.get_child(2)
		#
		#t.force_shapecast_update()
		#var collisions : int = t.get_collision_count()
		#for i : int in collisions:
			#var other = t.get_collider(i)
			#if(other.is_in_group("Enemies")):
				#other.pre_damage()
				#hitEnemies.append(other)

	#Reset attack stuff
	currentEffect = 0
	
	#Attack effects and deletion
	var tween = get_tree().create_tween()
	for attack in activeEffects:
		#tween.parallel()
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(attack.get_child(1),"modulate:a",1,0.2)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(attack.get_child(1), "modulate", Color.TRANSPARENT, 0.3)
		tween.tween_callback(attack.queue_free)
	tween.tween_callback(end_attack.bind(hitEnemies))


func _on_health_changed(newHealth:int, i:int):
	var healthLabel : Label = infoBoxes[i].get_node("CharacterHealth")
	
	if(newHealth <= 5 and newHealth > 3):
		healthLabel.add_theme_color_override("font_color", Color.YELLOW)
	elif(newHealth <= 3 and newHealth >0 ):
		healthLabel.add_theme_color_override("font_color", Color.RED)
	elif(newHealth <= 0):
		newHealth = 0
		var nameLabel : Label = infoBoxes[i].get_child(0)
		nameLabel.add_theme_color_override("font_color", Color.DIM_GRAY)
		healthLabel.add_theme_color_override("font_color", Color.DIM_GRAY)
	
	combatParty[i].current_health = newHealth
	healthLabel.text = "HP: " + str(newHealth) + "/" +  str(combatParty[i].max_health)
	
	
func _gui_input(event: InputEvent) -> void:
	print_debug("GUI_input pressed")
	if(event is InputEventKey):
		var ev: InputEventKey = event as InputEventKey
		if(ev.keycode == KEY_ESCAPE):
			print_debug("Escape Pressed!")
