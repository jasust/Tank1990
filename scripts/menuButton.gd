extends TextureButton

@export var text:String = "":
	set(value):
		text = value
		$Label.text = value
	
func _ready():
	hide_arrow()
	set_disabled_properties(disabled)

func show_arrow():
	$Arrow.visible = true
	$Arrow/AnimationPlayer.play('idle')
	
func hide_arrow():
	$Arrow.visible = false
	$Arrow/AnimationPlayer.stop()

func _on_focus_entered():
	show_arrow()
	$FocusedSound.play()

func _on_focus_exited():
	hide_arrow()

func _on_mouse_entered():
	if focus_mode:
		grab_focus()
	
func set_disabled_properties(isDsiabled:bool=true):
	if isDsiabled:
		set("focus_mode", FocusMode.FOCUS_NONE)
		set('mouse_default_cursor_shape', CursorShape.CURSOR_ARROW)
		$Label.set("theme_override_colors/font_color", Color(0.2,0.2,0.2,1))
	else:
		set("focus_mode", FocusMode.FOCUS_ALL)
		set('mouse_default_cursor_shape', CursorShape.CURSOR_POINTING_HAND)
		$Label.set("theme_override_colors/font_color", Color(1,1,1,1))
