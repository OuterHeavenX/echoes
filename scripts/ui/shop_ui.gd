extends CanvasLayer
## Shop: buy consumables/equipment with gold, rest at the inn (20G).
## Buying equipment grants ownership (inventory count >= 1); equipping
## is done in the Menu, and does not consume the owned item.

signal shop_closed

var _panel: PanelContainer
var _list: VBoxContainer
var _gold_label: Label
var _status_label: Label
var _shop_items: Array = ["potion", "ether", "antidote", "smoke", "rust_blade", "canal_cloak", "lantern_charm", "bell_brass_blade", "wardens_plate"]

func _ready() -> void:
	layer = 11
	visible = false
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(620, 420)
	_panel.position = Vector2(170, 60)
	add_child(_panel)
	var col: VBoxContainer = VBoxContainer.new()
	_panel.add_child(col)
	var title: Label = Label.new()
	title.text = "Shop  —  Bellweather Provisions"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)
	_gold_label = Label.new()
	col.add_child(_gold_label)
	_list = VBoxContainer.new()
	col.add_child(_list)
	var rest: Button = Button.new()
	rest.text = "Rest at the inn — 20G (full heal)"
	rest.custom_minimum_size = Vector2(200, 44)
	rest.pressed.connect(_on_rest)
	col.add_child(rest)
	_status_label = Label.new()
	col.add_child(_status_label)
	var close: Button = Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(200, 44)
	close.pressed.connect(close_shop)
	col.add_child(close)

func open_shop() -> void:
	visible = true
	_refresh()

func close_shop() -> void:
	visible = false
	shop_closed.emit()

func _refresh() -> void:
	_gold_label.text = "Gold: %d" % int(GameState.data.get("gold", 0))
	for child in _list.get_children():
		child.queue_free()
	for item_id in _shop_items:
		var it: Dictionary = Content.items.get(item_id, {})
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = "%s — %s (%dG, owned: %d)" % [str(it.get("name", item_id)), str(it.get("desc", "")), int(it.get("price", 0)), GameState.item_count(item_id)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var buy: Button = Button.new()
		buy.text = "Buy"
		buy.custom_minimum_size = Vector2(80, 40)
		buy.pressed.connect(_on_buy.bind(item_id))
		row.add_child(buy)
		_list.add_child(row)

func _on_buy(item_id: String) -> void:
	var price: int = int(Content.items.get(item_id, {}).get("price", 0))
	if int(GameState.data.get("gold", 0)) < price:
		_status_label.text = "Not enough gold."
		return
	GameState.data["gold"] = int(GameState.data["gold"]) - price
	GameState.add_item(item_id, 1)
	AudioMgr.play_sfx("confirm")
	_status_label.text = "Bought %s." % str(Content.items[item_id].get("name", item_id))
	_refresh()

func _on_rest() -> void:
	if int(GameState.data.get("gold", 0)) < 20:
		_status_label.text = "Not enough gold to rest."
		return
	GameState.data["gold"] = int(GameState.data["gold"]) - 20
	GameState.heal_party()
	AudioMgr.play_sfx("heal")
	_status_label.text = "Rested. The party is fully healed."
	_refresh()
