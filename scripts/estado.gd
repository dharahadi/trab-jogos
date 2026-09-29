extends Node

# Estado da partida. Fica em autoload, entao qualquer script alcanca
# como Estado.fichas, Estado.anotar("..."), etc.

signal bolso_mudou
signal caderno_mudou
signal mapa_mudou
signal aviso(texto: String)
signal marco_cumprido(numero: int, texto: String)

const LETRAS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

# Os cinco marcos da partida, na ordem do pitch.
const MARCOS := {
	1: "Descobrir que o corredor dá a volta.",
	2: "Encontrar o primeiro documento que não se resolve sozinho.",
	3: "Perceber que dois móveis de setores diferentes falam da mesma coisa.",
	4: "Abrir o cofre.",
	5: "Sair.",
}

# --- bolso ---
var fichas := 0
var tem_sanduiche := false
var tem_chave := false
var tem_cracha := false

# --- terminal ---
var partidas_terminal := 0
const COTA_PARTIDAS := 2
const PREMIO_PARTIDA := 3

# --- sorteio da partida ---
var cifra := {}      # "A" -> 7
var bilhete := ""    # tres letras, ex "ADE"
var senha := ""      # tres digitos, derivada das duas coisas acima

# --- progresso ---
var caderno: Array = []   # [{ "texto": String, "resolvido": bool }]
var visitados := {}       # id do setor -> true
var examinados := {}      # "setor:rotulo" -> true
var marcos := {}          # numero do marco -> true
var venceu := false
var tempo := 0.0


func _ready() -> void:
	sortear()


func _process(delta: float) -> void:
	if not venceu:
		tempo += delta


func sortear() -> void:
	# tabela de cifra: cada letra recebe um digito diferente
	var digitos := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	digitos.shuffle()
	cifra.clear()
	for i in LETRAS.size():
		cifra[LETRAS[i]] = digitos[i]

	# bilhete: tres letras sorteadas, sem repetir
	var sorteadas := LETRAS.duplicate()
	sorteadas.shuffle()
	bilhete = str(sorteadas[0]) + str(sorteadas[1]) + str(sorteadas[2])

	# a senha do cofre sai da cifra aplicada ao bilhete
	senha = ""
	for letra in bilhete:
		senha += str(cifra[letra])


func anotar(texto: String) -> void:
	for entrada in caderno:
		if entrada["texto"] == texto:
			return
	caderno.append({"texto": texto, "resolvido": false})
	caderno_mudou.emit()
	aviso.emit("Anotado no caderno.")
	Audio.tocar("anotar")


func riscar(texto: String) -> void:
	for entrada in caderno:
		if entrada["texto"] == texto:
			entrada["resolvido"] = true
	caderno_mudou.emit()


func cumprir_marco(numero: int) -> void:
	if marcos.has(numero):
		return
	marcos[numero] = true
	marco_cumprido.emit(numero, MARCOS[numero])


func gastar_fichas(n: int) -> bool:
	if fichas < n:
		return false
	fichas -= n
	bolso_mudou.emit()
	return true


func ganhar_fichas(n: int) -> void:
	fichas += n
	bolso_mudou.emit()
	Audio.tocar("ficha")


func marcar_examinado(setor: int, rotulo: String) -> void:
	examinados[str(setor) + ":" + rotulo] = true
	mapa_mudou.emit()


func foi_examinado(setor: int, rotulo: String) -> bool:
	return examinados.has(str(setor) + ":" + rotulo)


func examinados_no_setor(setor: int) -> int:
	var n := 0
	for chave in examinados:
		if str(chave).begins_with(str(setor) + ":"):
			n += 1
	return n


func reiniciar() -> void:
	fichas = 0
	tem_sanduiche = false
	tem_chave = false
	tem_cracha = false
	partidas_terminal = 0
	caderno.clear()
	visitados.clear()
	examinados.clear()
	marcos.clear()
	venceu = false
	tempo = 0.0
	sortear()
	bolso_mudou.emit()
	caderno_mudou.emit()
	mapa_mudou.emit()
