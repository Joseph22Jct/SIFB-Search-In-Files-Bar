@tool
extends Control
class_name OptionMenu

var SIFB : SIFB_Plugin

var changingInput : String = ""

func _enter_tree():
	%CloseButton.pressed.connect(CloseButton)
	if(SIFB!=null):
		%OS_Label.text = SIFB.openingShortcut.events[0].as_text_keycode()
		%SS_Label.text = SIFB.searchShortcut.events[0].as_text_keycode()
	%OS_Edit.pressed.connect(OpeningShortcutEdit)
	%SS_Edit.pressed.connect(SearchShortcutEdit)
	
func OpeningShortcutEdit():
	CheckForEditing()
	%OS_Label.text = "Waiting..."
	changingInput = "Opening"
	
	pass
	
func SearchShortcutEdit():
	CheckForEditing()
	%SS_Label.text = "Waiting..."
	changingInput = "Search"
	pass
	
func CloseButton():
	get_window().close_requested.emit()
	pass
	
func _input(event):
	if(changingInput!=""):
		if(event is InputEventKey):
			var keyevent:InputEventKey = event
			if(keyevent.keycode == KEY_CTRL or keyevent.keycode == KEY_SHIFT or keyevent.keycode == KEY_ALT):
				return
			match(changingInput):
				"Opening":
					SIFB.openingShortcut.events = [event]
					%OS_Label.text = SIFB.openingShortcut.events[0].as_text_keycode()
				"Search":
					SIFB.searchShortcut.events = [event]
					%SS_Label.text = SIFB.searchShortcut.events[0].as_text_keycode()
			SIFB.SaveNewShortcuts()
			changingInput = ""


func CheckForEditing():
	if(changingInput!=""):
		changingInput = ""
		%OS_Label.text = SIFB.openingShortcut.events[0].as_text_keycode()
		%SS_Label.text = SIFB.searchShortcut.events[0].as_text_keycode()
