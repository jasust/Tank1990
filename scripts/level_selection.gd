extends Control

const TOTAL_LEVELS = 36
var unlockedLevels: int = TOTAL_LEVELS

signal start_level(number:int)
signal end_level(isManual:bool)

func _ready():
	$SceneEnteredSound.play()
	for i in global.players:
		unlockedLevels = mini(unlockedLevels, global.players[i].unlockedLevels)

	const LEVEL_BUTTON = preload('res://scripts/menu_button.tscn')
	for i in range(TOTAL_LEVELS):
		var levelButton = LEVEL_BUTTON.instantiate()
		levelButton.name = "Level%d" % (i+1)
		levelButton.text = "Level %d" % (i+1)
		if unlockedLevels > i:
			levelButton.pressed.connect(open_level.bind(i+1))
		else:
			levelButton.disabled = true
		$ScrollContainer/GridContainer.add_child(levelButton)
		
	await get_tree().process_frame
	var focusButton = get_node('ScrollContainer/GridContainer/Level%d' % unlockedLevels)
	focusButton.grab_focus()
	$ScrollContainer.ensure_control_visible(focusButton)

func _on_home_button_pressed():
	end_level.emit(true)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_filedialog_up_one_level"):
		end_level.emit(true)

func open_level(number:int):
	start_level.emit(number)
