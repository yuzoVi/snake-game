extends Node2D

const GRID_W := 20
const GRID_H := 20
const CELL := 30
const TICK_RATE := 0.15

var snake: Array[Vector2i] = []
var dir := Vector2i.RIGHT
var next_dir := Vector2i.RIGHT
var food := Vector2i.ZERO
var score := 0
var best := 0
var dead := false
var tick_timer := 0.0

func _ready() -> void:
	_new_game()

func _new_game() -> void:
	var cx := GRID_W / 2
	var cy := GRID_H / 2
	snake = [Vector2i(cx, cy), Vector2i(cx - 1, cy), Vector2i(cx - 2, cy)]
	dir = Vector2i.RIGHT
	next_dir = Vector2i.RIGHT
	score = 0
	dead = false
	tick_timer = 0.0
	_place_food()
	queue_redraw()

func _place_food() -> void:
	var free: Array[Vector2i] = []
	for x in GRID_W:
		for y in GRID_H:
			var p := Vector2i(x, y)
			if p not in snake:
				free.append(p)
	if not free.is_empty():
		food = free[randi() % free.size()]

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if dead:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_new_game()
		return
	match event.keycode:
		KEY_UP, KEY_W:
			if dir != Vector2i.DOWN:  next_dir = Vector2i.UP
		KEY_DOWN, KEY_S:
			if dir != Vector2i.UP:    next_dir = Vector2i.DOWN
		KEY_LEFT, KEY_A:
			if dir != Vector2i.RIGHT: next_dir = Vector2i.LEFT
		KEY_RIGHT, KEY_D:
			if dir != Vector2i.LEFT:  next_dir = Vector2i.RIGHT

func _process(delta: float) -> void:
	if dead:
		return
	tick_timer += delta
	if tick_timer >= TICK_RATE:
		tick_timer -= TICK_RATE
		_step()

func _step() -> void:
	dir = next_dir
	var head := snake[0] + dir
	head.x = posmod(head.x, GRID_W)
	head.y = posmod(head.y, GRID_H)
	if head in snake:
		dead = true
		best = max(best, score)
		queue_redraw()
		return
	snake.push_front(head)
	if head == food:
		score += 1
		_place_food()
	else:
		snake.pop_back()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bw := GRID_W * CELL
	var bh := GRID_H * CELL

	# Board
	draw_rect(Rect2(0, 0, bw, bh), Color(0.05, 0.05, 0.05))
	for x in GRID_W:
		for y in GRID_H:
			draw_rect(Rect2(x * CELL + 1, y * CELL + 1, CELL - 2, CELL - 2), Color(0.08, 0.08, 0.08))

	# Food
	draw_rect(Rect2(food.x * CELL + 4, food.y * CELL + 4, CELL - 8, CELL - 8), Color(0.95, 0.2, 0.2))

	# Snake (tail → head so head renders on top)
	for i in range(snake.size() - 1, -1, -1):
		var s := snake[i]
		var col := Color(0.3, 0.9, 0.3) if i == 0 else Color(0.15, 0.6, 0.15)
		draw_rect(Rect2(s.x * CELL + 1, s.y * CELL + 1, CELL - 2, CELL - 2), col)

	# HUD bar
	draw_rect(Rect2(0, bh, bw, 40), Color(0.1, 0.1, 0.1))
	draw_string(font, Vector2(10, bh + 28),
		"Score: %d    Best: %d" % [score, best],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.9, 0.9))

	# Game-over overlay
	if dead:
		draw_rect(Rect2(0, 0, bw, bh), Color(0.0, 0.0, 0.0, 0.65))
		draw_string(font, Vector2(0, bh / 2.0 - 20),
			"GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, bw, 42, Color(1.0, 0.3, 0.3))
		draw_string(font, Vector2(0, bh / 2.0 + 36),
			"Enter / Space to restart", HORIZONTAL_ALIGNMENT_CENTER, bw, 20, Color(0.9, 0.9, 0.9))
