extends CanvasLayer

# Tela de titulo. Some na primeira tecla.

signal comecou


func _ready() -> void:
	layer = 20

	var fundo := ColorRect.new()
	fundo.color = Color(0.961, 0.957, 0.945)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "EXPEDIENTE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", Color(0.10, 0.10, 0.10))
	coluna.add_child(titulo)

	var linha := ColorRect.new()
	linha.color = Color(0.12, 0.31, 0.27)
	linha.custom_minimum_size = Vector2(420, 2)
	coluna.add_child(linha)

	var sub := Label.new()
	sub.text = "Um escape room 2D dentro de um escritório que não tem fim."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	coluna.add_child(sub)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, 40)
	coluna.add_child(espaco)

	var comandos := Label.new()
	comandos.text = "← →  andar          E  interagir          ESC  pausa"
	comandos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comandos.add_theme_font_size_override("font_size", 14)
	comandos.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	coluna.add_child(comandos)

	var comecar := Label.new()
	comecar.text = "qualquer tecla para bater o ponto"
	comecar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comecar.add_theme_font_size_override("font_size", 13)
	comecar.add_theme_color_override("font_color", Color(0.12, 0.31, 0.27))
	coluna.add_child(comecar)

	var rodape := Label.new()
	rodape.text = "Grupo 07 · Dhara Hadi · Júlia Bettiol · Thomaz Szeckir"
	rodape.position = Vector2(0, 600)
	rodape.size = Vector2(1152, 20)
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rodape.add_theme_font_size_override("font_size", 12)
	rodape.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	add_child(rodape)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		visible = false
		Audio.tocar("porta_abrir")
		comecou.emit()
		get_viewport().set_input_as_handled()
