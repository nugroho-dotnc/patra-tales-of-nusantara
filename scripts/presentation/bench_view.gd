class_name BenchView 
extends HBoxContainer

signal card_selected(selected_card: CardInstance)

const CARD_SCENE: PackedScene = preload(
	"res://scene/components/card_view.tscn"
)

var player: PlayerState
var selected_card_id: String = ""
var card_views: Array[CardView] = []
var empty_labels: Array[Label] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for index in range(PlayerState.BENCH_LIMIT):
		var slot := get_node(
			"Slot%d" % (index + 1)
			) as PanelContainer
		
		var empty_label := slot.get_node("EmptyLabel") as Label
		empty_labels.append(empty_label)
		
		var view := CARD_SCENE.instantiate() as CardView
		view.custom_minimum_size = Vector2(180, 160)
		view.card_clicked.connect(_on_card_clicked)
		
		slot.add_child(view)
		view.hide()
		card_views.append(view)

func bind_player(new_player: PlayerState) -> void:
	player = new_player
	selected_card_id = ""
	refresh()
	
func refresh() -> void:
	if player == null:
		return
	
	for index in range(PlayerState.BENCH_LIMIT):
		var instance_id: String = player.bench_slots[index]
		var card: CardInstance = player.get_card(instance_id)
		var occupied: bool = card != null
		
		empty_labels[index].visible = not occupied
		card_views[index].visible = occupied
		
		if occupied:
			card_views[index].bind_card(card)
			card_views[index].set_selected(
				instance_id == selected_card_id
			)
		else:
			card_views[index].set_selected(false)

func set_selected_card(instance_id: String) -> void:
	selected_card_id = instance_id
	refresh()

func _on_card_clicked(clicked_card: CardInstance) -> void:
	card_selected.emit(clicked_card)
# Called every frame. 'delta' is the elapsed time since the previous frame.
