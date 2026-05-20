extends CanvasLayer

const BAR_WIDTH   := 180.0
const HP_HEIGHT   := 20.0
const ST_HEIGHT   := 14.0
const MARGIN      := 16.0
const BAR_GAP     := 5.0

var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_label: Label
var _st_bg: ColorRect
var _st_fill: ColorRect
var _player: Node = null

func _ready() -> void:
	var hp_y := MARGIN
	var st_y := MARGIN + HP_HEIGHT + BAR_GAP

	_hp_bg = _make_rect(Color(0.1, 0.1, 0.1, 0.75), Vector2(BAR_WIDTH, HP_HEIGHT), Vector2(MARGIN, hp_y))
	_hp_fill = _make_rect(Color(0.78, 0.12, 0.12, 1), Vector2(BAR_WIDTH, HP_HEIGHT), Vector2(MARGIN, hp_y))

	_hp_label = Label.new()
	_hp_label.position = Vector2(MARGIN + 6.0, hp_y)
	_hp_label.size = Vector2(BAR_WIDTH, HP_HEIGHT)
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_hp_label)

	_st_bg   = _make_rect(Color(0.1, 0.1, 0.1, 0.75), Vector2(BAR_WIDTH, ST_HEIGHT), Vector2(MARGIN, st_y))
	_st_fill = _make_rect(Color(0.85, 0.72, 0.1, 1),  Vector2(BAR_WIDTH, ST_HEIGHT), Vector2(MARGIN, st_y))

func _make_rect(color: Color, size: Vector2, pos: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = size
	r.position = pos
	add_child(r)
	return r

func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var hp         = _player.get("hp")
	var max_hp     = _player.get("max_hp")
	var stamina    = _player.get("stamina")
	var max_stamina = _player.get("max_stamina")

	if hp != null and max_hp != null and max_hp > 0:
		var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		_hp_fill.size.x = BAR_WIDTH * ratio
		_hp_label.text = "HP  %d / %d" % [hp, max_hp]
		_hp_fill.color = Color(0.78, 0.12, 0.12, 1) if ratio > 0.4 else Color(0.95, 0.08, 0.08, 1)

	if stamina != null and max_stamina != null and max_stamina > 0:
		var ratio := clampf(float(stamina) / float(max_stamina), 0.0, 1.0)
		_st_fill.size.x = BAR_WIDTH * ratio
		# Dims toward grey when nearly empty
		_st_fill.color = Color(0.85, 0.72, 0.1, 1) if ratio > 0.25 else Color(0.55, 0.50, 0.15, 1)
