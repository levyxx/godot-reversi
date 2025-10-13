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
	# ノードへの参照を取得
	turn_label = get_node_or_null("../UI/TurnLabel")
	score_label = get_node_or_null("../UI/ScoreLabel")
	result_panel = get_node_or_null("../UI/ResultPanel")
	game_board = get_node_or_null("../GameBoard")
	
	if result_panel:
		result_label = result_panel.get_node_or_null("VBoxContainer/ResultLabel")
		retry_button = result_panel.get_node_or_null("VBoxContainer/HBoxContainer/RetryButton")
		quit_button = result_panel.get_node_or_null("VBoxContainer/HBoxContainer/QuitButton")
	
	init_board()
	update_ui()
	
	if result_panel:
		result_panel.visible = false
	
	if retry_button:
		retry_button.pressed.connect(_on_retry)
	if quit_button:
		quit_button.pressed.connect(_on_quit)

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
		
		if 0 <= col < BOARD_SIZE and 0 <= row < BOARD_SIZE:
			if can_place(row, col, 1):
				place_piece(row, col, 1)
				update_ui()
				
				if not can_move(get_next_player(1)):
					if not can_move(1):
						end_game()
						return
					is_player_turn = true
				else:
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
	
	while 0 <= r and r < BOARD_SIZE and 0 <= c and c < BOARD_SIZE:
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

func get_next_player(player: int) -> int:
	"""次のプレイヤーを取得"""
	return -player

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
		
		if not can_move(1):
			if not can_move(-1):
				end_game()
				return
			is_player_turn = true
		else:
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
