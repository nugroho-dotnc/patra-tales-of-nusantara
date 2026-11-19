class_name CardView extends PanelContainer

@onready var name_label: Label = $Content/NameLabel
@onready var daya_label: Label = $Content/DayaLabel
@onready var sukma_label: Label = $Content/SukmaLabel
@onready var status_label: Label = $Content/StatusLabel

signal card_clicked(clicked_card: CardInstance)
var card: CardInstance


func bind_card(new_card: CardInstance) -> void:
	card = new_card
	refresh()


func refresh() -> void:
	if card == null:
		name_label.text = "Nama Kartu"
		daya_label.text = "Daya: —"
		sukma_label.text = "Sukma: —"
		status_label.text = "Belum ada kartu"
		return

	name_label.text = card.definition.display_name
	daya_label.text = "Daya: %d" % card.get_daya()
	sukma_label.text = "Sukma: %d / %d" % [
		card.current_sukma,
		card.definition.max_sukma
	]

	if card.is_dead():
		status_label.text = "Gugur"
	elif card.attacked_this_round:
		status_label.text = "Sudah menyerang"
	else:
		status_label.text = "Aktif"

func _gui_input(event: InputEvent) -> void:
	if card == null:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card_clicked.emit(card)
			accept_event()
	
func set_selected(value: bool)-> void:
	if value:
		modulate = Color(1.0, 0.85, 0.45)
	else:
		modulate = Color.WHITE
