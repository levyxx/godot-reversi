extends Node2D

const BOARD_SIZE = 8
const CELL_SIZE = 50
const BOARD_START_X = 100
const BOARD_START_Y = 100

@onready var game_manager = get_parent().get_node("GameManager")

func _draw():
	var board = game_manager.get_board()
	
	# 盤面の背景
	draw_rect(Rect2(BOARD_START_X, BOARD_START_Y, BOARD_SIZE * CELL_SIZE, BOARD_SIZE * CELL_SIZE), Color.GREEN)
	
	# グリッドラインの描画
	for i in range(BOARD_SIZE + 1):
		draw_line(Vector2(BOARD_START_X, BOARD_START_Y + i * CELL_SIZE), 
				 Vector2(BOARD_START_X + BOARD_SIZE * CELL_SIZE, BOARD_START_Y + i * CELL_SIZE), Color.BLACK, 2)
		draw_line(Vector2(BOARD_START_X + i * CELL_SIZE, BOARD_START_Y), 
				 Vector2(BOARD_START_X + i * CELL_SIZE, BOARD_START_Y + BOARD_SIZE * CELL_SIZE), Color.BLACK, 2)
	
	# コマの描画
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			var x = BOARD_START_X + j * CELL_SIZE + CELL_SIZE / 2
			var y = BOARD_START_Y + i * CELL_SIZE + CELL_SIZE / 2
			
			if board[i][j] == 1:
				draw_circle(Vector2(x, y), CELL_SIZE / 2 - 5, Color.WHITE)
			elif board[i][j] == -1:
				draw_circle(Vector2(x, y), CELL_SIZE / 2 - 5, Color.BLACK)
			elif game_manager.is_player_turn and game_manager.is_placeable(i, j):
				# 置ける場所を表示
				draw_circle(Vector2(x, y), 5, Color.YELLOW)
