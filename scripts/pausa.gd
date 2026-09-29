extends CanvasLayer

# Pausa com controle de volume.

signal reiniciar_pedido

var _slider: HSlider


func _ready() -> void:
	layer = 15
	visible = false

	var fundo := ColorRect.new()
	fundo.color = Color(0.96, 0.95, 0.93, 0.92)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 16)
	coluna.custom_minimum_size = Vector2(340, 0)
	centro.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "EXPEDIENTE SUSPENSO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", Color(0.10, 0.10, 0.10))
	coluna.add_child(titulo)

	var rotulo := Label.new()
	rotulo.text = "Volume"
	rotulo.add_theme_font_size_override("font_size", 13)
	rotulo.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	coluna.add_child(rotulo)

	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.05
	_slider.value = Audio.volume
	_slider.custom_minimum_size = Vector2(340, 24)
	_slider.value_changed.connect(func(v): Audio.volume = v)
	coluna.add_child(_slider)

	var continuar := Button.new()
	continuar.text = "Continuar"
	continuar.custom_minimum_size = Vector2(0, 38)
	continuar.pressed.connect(fechar)
	coluna.add_child(continuar)

	var recomecar := Button.new()
	recomecar.text = "Recomeçar com outra cifra"
	recomecar.custom_minimum_size = Vector2(0, 38)
	recomecar.pressed.connect(func():
		fechar()
		reiniciar_pedido.emit())
	coluna.add_child(recomecar)


func abrir() -> void:
	_slider.value = Audio.volume
	visible = true
	get_tree().paused = true


func fechar() -> void:
	visible = false
	get_tree().paused = false
