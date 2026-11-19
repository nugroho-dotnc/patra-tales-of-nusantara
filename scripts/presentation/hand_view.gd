class_name HandView
extends HBoxContainer

signal card_selected(selected_card: CardInstance)

const CARD_SCENE: PackedScene = preload(
	"res://scene/components/card_view.tscn"
)

var player: PlayerState
var selected_card_id: String = ""
var card_views: Array[CardView] = []


func _ready() -> void:
	for index in range(PlayerState.HAND_LIMIT):
		var view := CARD_SCENE.instantiate() as CardView
		view.custom_minimum_size = Vector2(180, 160)
		view.card_clicked.connect(_on_card_clicked)

		add_child(view)
		view.hide()
		card_views.append(view)


func bind_player(new_player: PlayerState) -> void:
	player = new_player
	selected_card_id = ""
	refresh()


func refresh() -> void:
	if player == null:
		return

	for index in range(PlayerState.HAND_LIMIT):
		var view: CardView = card_views[index]

		if index >= player.hand_ids.size():
			view.hide()
			view.set_selected(false)
			continue

		var instance_id: String = player.hand_ids[index]
		var card: CardInstance = player.get_card(instance_id)

		view.bind_card(card)
		view.set_selected(instance_id == selected_card_id)
		view.tooltip_text = "Biaya Cakra: %d" % card.definition.cost
		view.show()


func set_selected_card(instance_id: String) -> void:
	selected_card_id = instance_id
	refresh()


func _on_card_clicked(clicked_card: CardInstance) -> void:
	card_selected.emit(clicked_card)
