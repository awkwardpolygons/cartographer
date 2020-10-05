tool
extends PopupDialog

func _ready():
	popup_centered()

func _on_patreon_pressed():
	var err = OS.shell_open("https://godotengine.org")
#	prints("_on_patreon_pressed", err)
