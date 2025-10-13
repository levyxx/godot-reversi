extends Control

func _ready():
	print("Title scene ready")
	
	# VBoxContainerの設定
	$VBoxContainer.anchor_left = 0.5
	$VBoxContainer.anchor_top = 0.5
	$VBoxContainer.anchor_right = 0.5
	$VBoxContainer.anchor_bottom = 0.5
	$VBoxContainer.offset_left = -150
	$VBoxContainer.offset_top = -100
	
	# タイトルラベルの設定
	var title = $VBoxContainer/Title
	title.text = "リバーシ"
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.custom_minimum_size = Vector2(300, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# スタートボタンの設定
	var start_button = $VBoxContainer/StartButton
	start_button.text = "ゲーム開始"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.pressed.connect(_on_start_pressed)
	
	print("Title scene setup complete")

func _on_start_pressed():
	print("Start button pressed!")
	get_tree().change_scene_to_file("res://scenes/game_new.tscn")
