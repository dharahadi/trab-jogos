# Expediente - projeto em Godot

Grupo 07. Godot 4.4 ou mais novo, GDScript.

## Rodar

Abrir o Godot, **Importar**, apontar para o `project.godot` desta pasta, F5.

Teclas: setas ou A/D para andar, **E** para interagir, **ESC** para pausar (e para fechar enigma), **R** para recomeçar depois de vencer.

## O que funciona

A cadeia inteira do pitch, do começo ao fim:

1. Setor 01, planta de evacuação -> descobre o elevador.
2. Setor 02, terminal -> vencer 3 rodadas -> 3 fichas.
3. Setor 05, máquina -> sanduíche por 2 fichas. O café custa 1 e não serve para nada, como planejado.
4. Setor 04, colega -> troca o sanduíche pela chave.
5. Setor 01 e 03, quadro de avisos e armário 14 -> tabela de cifra + bilhete de três letras.
6. Porta 06 com a chave -> setor 06, cofre, senha de três dígitos -> crachá nível 4.
7. Setor 01, elevador -> fim.

Além disso:

- **Minimapa** que se desenha sozinho, com setor visitado, setor conhecido mas não visitado, porta trancada tracejada e um ponto por móvel examinado.
- **Caderno** que anota e risca a linha quando a pendência se resolve.
- **Os cinco marcos** do slide 10, detectados de verdade. O primeiro dispara quando o jogador completa uma volta inteira sem perceber.
- **Tela de título**, **pausa com controle de volume** e **tela final** com resumo e os marcos cumpridos.
- **14 efeitos sonoros** e o zumbido de lâmpada fluorescente em loop.
- Cifra e bilhete sorteados a cada partida, então a senha nunca repete.

## Os arquivos

```
project.godot        configuração e autoloads
main.tscn            cena única, só carrega o script do jogo
dados/setores.gd     TABELA DOS 6 SETORES E DOS MÓVEIS  <- mexam aqui primeiro
scripts/estado.gd    autoload: fichas, itens, cifra, caderno, marcos
scripts/audio.gd     autoload: efeitos sonoros
scripts/jogo.gd      corredor circular, interação, troca de setor
scripts/jogador.gd   o boneco
scripts/overlay.gd   as três famílias de enigma
scripts/hud.gd       cabeçalho, prompt, bolso, caderno
scripts/minimapa.gd  o mapa que se desenha
scripts/titulo.gd    tela de título
scripts/pausa.gd     pausa e volume
```

Quase tudo é construído por código, sem cenas montadas no editor. Enquanto a arte não existe, é mais rápido mexer em tabela do que arrastar nó.

## Como o corredor circular funciona

O truque está em `jogo.gd`. **O jogador nunca se move** - fica travado no centro da tela. O que muda é a posição de cada móvel:

```gdscript
func _delta_anel(de: float, para: float) -> float:
	return fposmod(para - de + perimetro / 2.0, perimetro) - perimetro / 2.0
```

Isso devolve a distância pelo caminho mais curto do anel. Como nada nunca está "do outro lado", não existe momento de emenda e não existe câmera para pular quando a volta fecha.

O perímetro de cada setor está em `dados/setores.gd`. A 160 px/s, o setor 01 (1900 px) dá uma volta em ~12 segundos, que é o alvo do GDD.

## Sobre o som

Os efeitos são **gerados por código** em `audio.gd`, sem nenhum arquivo de áudio. Isso existe para o jogo ter som agora, não para ficar assim. Quando vocês gravarem ou baixarem os sons de verdade, troquem o corpo de `_criar_sons()` por `load("res://sons/porta.wav")` e o resto continua funcionando igual.

## Onde mexer para cada coisa

| Quero... | Vou em |
|---|---|
| mover um móvel, criar setor novo | `dados/setores.gd` |
| mudar preço, prêmio ou cota | `scripts/estado.gd` |
| escrever texto de documento | `scripts/overlay.gd`, funções `abrir_*` |
| mudar velocidade ou raio de interação | constantes no topo de `jogo.gd` |
| trocar retângulo por sprite | `_criar_movel()` em `jogo.gd` |
| trocar som gerado por arquivo | `_criar_sons()` em `audio.gd` |

## O que falta para o T2

1. **Sprites no lugar dos retângulos.** Trocar `ColorRect` por `Sprite2D` em `_criar_movel()`.
2. **Animação do jogador.** Hoje `jogador.gd` desenha com `_draw()`. Trocar por `AnimatedSprite2D` com as três animações.
3. **Sons de verdade** no lugar dos gerados.
4. **Mais variedade no terminal.** Hoje são cinco regras (quadrados, múltiplos de 5, pares, primos, múltiplos de 3). É o pedaço mais fraco do conjunto.
5. **Balanceamento** com gente de fora: velocidade, perímetro, economia.
6. **Salvamento** - só no T3, segundo o próprio GDD.

## Divisão possível entre três

- **Arte e animação:** itens 1 e 2. Mexe em `_criar_movel` e `jogador.gd`, não encosta na lógica.
- **Som e interface:** item 3, mais ajustes de HUD e minimapa.
- **Conteúdo e balanceamento:** itens 4 e 5, mais enigmas em `overlay.gd` e setores em `dados/setores.gd`.

Os três tocam arquivos diferentes, então dá para trabalhar em paralelo sem conflito.
