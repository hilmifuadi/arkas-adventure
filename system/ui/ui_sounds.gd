class_name UiSounds
## Menyambungkan bunyi menu (gerak fokus, pilih) ke semua Button di bawah sebuah node.


static func wire(root:Node) -> void:
	for button in root.find_children("*","Button",true,false):
		connect_button(button)


static func connect_button(button:Button) -> void:
	if !button.pressed.is_connected(play_accept):
		button.pressed.connect(play_accept)
		button.focus_entered.connect(play_move)


static func play_accept() -> void:
	Audio.play_sfx("menu_accept")


static func play_move() -> void:
	Audio.play_sfx("menu_move")
