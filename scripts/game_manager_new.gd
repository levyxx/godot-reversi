extends Node

const BOARD_SIZE = 8
const CELL_SIZE = 50
const BOARD_START_X = 100
const BOARD_START_Y = 100

# ゲーム状態
var board = []
var is_player_turn = true
var game_over = false
var player_score = 0
var ai_score = 0

# UI参照
var turn_label
var score_label
var result_panel
var result_label
var retry_button
var quit_button
var game_board

func _ready():
	print("GameManager: _ready called")
	
	# ノードへの参照を取得
	turn_label = get_node("../UI/TurnLabel")
	score_label = get_node("../UI/ScoreLabel")
	result_panel = get_node("../UI/ResultPanel")
	game_board = get_node("../GameBoard")
	
	result_label = result_panel.get_node("VBoxContainer/ResultLabel")
	retry_button = result_panel.get_node("VBoxContainer/HBoxContainer/RetryButton")
	quit_button = result_panel.get_node("VBoxContainer/HBoxContainer/QuitButton")
	
	# UI設定
	turn_label.text = "あなたのターン"
	turn_label.position = Vector2(100, 500)
	
	score_label.text = "あなた: 0  |  AI: 0"
	score_label.position = Vector2(100, 530)
	
	result_panel.position = Vector2(100, 100)
	result_panel.size = Vector2(400, 300)
	
	result_label.text = "ゲーム結果"
	result_label.add_theme_font_size_override("font_size", 40)
	
	retry_button.text = "リトライ"
	retry_button.custom_minimum_size = Vector2(150, 50)
	
	quit_button.text = "ゲーム終了"
	quit_button.custom_minimum_size = Vector2(150, 50)
	
	# ボタンシグナル接続
	retry_button.pressed.connect(_on_retry)
	quit_button.pressed.connect(_on_quit)
	
	# ゲーム初期化
	init_board()
	update_ui()
	result_panel.visible = false
	
	print("GameManager: Setup complete")

func init_board():
	board.clear()
	for i in range(BOARD_SIZE):
		board.append([])
		for j in range(BOARD_SIZE):
			board[i].append(0)  # 0:空, 1:プレイヤー, -1:AI
	
	# 初期配置
	board[3][3] = 1
	board[3][4] = -1
	board[4][3] = -1
	board[4][4] = 1
	
	is_player_turn = true
	game_over = false

func _input(event):
	if game_over or not is_player_turn:
		return
	
	if event is InputEventMouseButton and event.pressed:
		var col = int((event.position.x - BOARD_START_X) / CELL_SIZE)
		var row = int((event.position.y - BOARD_START_Y) / CELL_SIZE)
		
		if 0 <= col and col < BOARD_SIZE and 0 <= row and row < BOARD_SIZE:
			if can_place(row, col, 1):
				place_piece(row, col, 1)
				update_ui()
				
				# AIのターンに移る
				var ai_player = -1
				if not can_move(ai_player):
					# AIが置けない場合、プレイヤーが置けるか確認
					if not can_move(1):
						end_game()
						return
					# プレイヤーが置ける場合はプレイヤーのターンのままに
					is_player_turn = true
				else:
					# AIが置ける場合はAIのターンに
					is_player_turn = false
					await get_tree().create_timer(1.0).timeout
					ai_move()

func get_flipped_pieces(row: int, col: int, player: int) -> Array:
	"""指定位置にコマを置いた場合、ひっくり返るコマのリストを返す"""
	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return []
	if board[row][col] != 0:
		return []
	
	var all_flipped = []
	var directions = [
		[-1, -1], [-1, 0], [-1, 1],
		[0, -1],           [0, 1],
		[1, -1],  [1, 0],  [1, 1]
	]
	
	for dir in directions:
		var flipped = check_direction(row, col, dir[0], dir[1], player)
		if flipped.size() > 0:
			all_flipped.append_array(flipped)
	
	return all_flipped

func can_place(row: int, col: int, player: int) -> bool:
	"""指定位置にコマを置けるかを判定"""
	var flipped = get_flipped_pieces(row, col, player)
	return flipped.size() > 0

func place_piece(row: int, col: int, player: int) -> void:
	"""コマを置いてひっくり返す処理"""
	board[row][col] = player
	
	var directions = [
		[-1, -1], [-1, 0], [-1, 1],
		[0, -1],           [0, 1],
		[1, -1],  [1, 0],  [1, 1]
	]
	
	for dir in directions:
		var flipped = check_direction(row, col, dir[0], dir[1], player)
		for pos in flipped:
			board[pos[0]][pos[1]] = player

func check_direction(row: int, col: int, dr: int, dc: int, player: int) -> Array:
	"""指定された方向でひっくり返るコマのリストを返す"""
	var flipped = []
	var r = row + dr
	var c = col + dc
	
	while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE:
		if board[r][c] == 0:
			return []
		if board[r][c] == player:
			return flipped
		flipped.append([r, c])
		r += dr
		c += dc
	
	return []

func can_move(player: int) -> bool:
	"""プレイヤーが移動可能かを判定"""
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			if can_place(i, j, player):
				return true
	return false

func ai_move() -> void:
	"""AI（コンピュータ）の手を実行"""
	var valid_moves = []
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			if can_place(i, j, -1):
				valid_moves.append([i, j])
	
	if valid_moves.size() > 0:
		var move = valid_moves[randi() % valid_moves.size()]
		place_piece(move[0], move[1], -1)
		update_ui()
		
		# プレイヤーが置けるか確認
		if not can_move(1):
			# プレイヤーが置けない場合、AIが置けるか確認
			if not can_move(-1):
				# 両方置けない場合はゲーム終了
				end_game()
				return
			# AIが置ける場合はAIのターンのままに
			is_player_turn = false
		else:
			# プレイヤーが置ける場合はプレイヤーのターンに
			is_player_turn = true

func update_ui() -> void:
	"""UI を更新"""
	if game_board:
		game_board.queue_redraw()
	
	var player_count = 0
	var ai_count = 0
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			if board[i][j] == 1:
				player_count += 1
			elif board[i][j] == -1:
				ai_count += 1
	
	player_score = player_count
	ai_score = ai_count
	
	if turn_label:
		if is_player_turn:
			turn_label.text = "あなたのターン"
		else:
			turn_label.text = "AIのターン"
	
	if score_label:
		score_label.text = "あなた: %d  |  AI: %d" % [player_score, ai_score]

func end_game() -> void:
	"""ゲームを終了"""
	game_over = true
	
	var result_text = ""
	if player_score > ai_score:
		result_text = "あなたの勝ち！\nあなた: %d  AI: %d" % [player_score, ai_score]
	elif ai_score > player_score:
		result_text = "AIの勝ち\nあなた: %d  AI: %d" % [player_score, ai_score]
	else:
		result_text = "同点！\nあなた: %d  AI: %d" % [player_score, ai_score]
	
	if result_label:
		result_label.text = result_text
	
	if result_panel:
		result_panel.visible = true

func get_board() -> Array:
	"""ボードを取得"""
	return board

func is_placeable(row: int, col: int) -> bool:
	"""プレイヤーがその位置にコマを置けるか"""
	return can_place(row, col, 1)

func _on_retry() -> void:
	"""リトライボタン押下時"""
	init_board()
	game_over = false
	if result_panel:
		result_panel.visible = false
	update_ui()

func _on_quit() -> void:
	"""ゲーム終了ボタン押下時"""
	get_tree().change_scene_to_file("res://scenes/title.tscn")
