extends CanvasLayer

const BAR_WIDTH  := 180.0
const BAR_HEIGHT := 20.0
const MARGIN     := 16.0

var _bar_bg: ColorRect
var _bar_fill: ColorRect
var _label: Label
var _player: Node = null

func _ready() -> void:
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.1, 0.1, 0.1, 0.75)
	_bar_bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_bg.position = Vector2(MARGIN, MARGIN)
	add_child(_bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.78, 0.12, 0.12, 1)
	_bar_fill.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar_fill.position = Vector2(MARGIN, MARGIN)
	add_child(_bar_fill)

	_label = Label.new()
	_label.position = Vector2(MARGIN + 6.0, MARGIN)
	_label.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_label)

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var hp     = _player.get("hp")
	var max_hp = _player.get("max_hp")
	if hp == null or max_hp == null or max_hp == 0:
		return

	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_bar_fill.size.x = BAR_WIDTH * ratio
	_label.text = "HP  %d / %d" % [hp, max_hp]

	# Bar shifts darker red when low
	_bar_fill.color = Color(0.78, 0.12, 0.12, 1) if ratio > 0.4 else Color(0.95, 0.08, 0.08, 1)
