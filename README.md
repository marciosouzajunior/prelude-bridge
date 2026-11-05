# Prelude Bridge

Ponte experimental para usar a interface **E.R. Pires Prelude MIDI↔USB
antiga** no macOS, sem instalar kexts ou drivers de kernel.

A geração antiga da Prelude usa um conversor serial FTDI (`VID 0403`,
`PID 6001`) e, por isso, aparece no macOS como `/dev/cu.usbserial-*`, mas não
como dispositivo USB-MIDI. Este programa lê MIDI serial a 31.250 baud e publica
uma fonte CoreMIDI virtual chamada **Prelude MIDI Bridge**.

> Projeto independente, sem vínculo ou endosso da E.R. Pires, Yamaha, FTDI ou
> Apple. Os nomes citados pertencem aos respectivos titulares.

## Status

Validado em Apple Silicon com uma Prelude antiga ligada ao MIDI OUT de uma
Yamaha DTXplorer. Foram recebidos Note On/Off no canal 10, velocity, MIDI Clock
e Active Sensing. Outras revisões do hardware ainda precisam de confirmação.

## Requisitos

- macOS 13 ou posterior;
- Xcode Command Line Tools ou Xcode com Swift;
- uma Prelude antiga reconhecida como `/dev/cu.usbserial-*`.

## Compilar e testar

```sh
git clone https://github.com/marciosouzajunior/prelude-bridge.git
cd prelude-bridge
swift test
swift build -c release
```

## Usar

Conecte a Prelude e execute:

```sh
.build/release/prelude-bridge
```

Se houver apenas uma porta `cu.usbserial`, ela será detectada automaticamente.
Com várias interfaces seriais conectadas, escolha explicitamente:

```sh
.build/release/prelude-bridge --serial /dev/cu.usbserial-SEU_SERIAL
```

Deixe o processo aberto e selecione **Prelude MIDI Bridge** como entrada no
Reaper, GarageBand ou outro aplicativo CoreMIDI. A fonte virtual desaparece
quando o processo é encerrado com `Ctrl-C`.

Para observar os bytes MIDI:

```sh
.build/release/prelude-bridge --monitor --no-midi
```

Exemplo de uma nota no canal 10:

```text
99 30 27  # Note On, nota 48, velocity 39
99 30 00  # Note Off por velocity zero
```

Use `--help` para listar todas as opções.

## Solução de problemas

**Nenhuma porta encontrada**

```sh
ls /dev/cu.usbserial-*
```

Reconecte a Prelude e tente outra porta USB ou adaptador.

**Device busy**

Feche outros programas que possam ter aberto a serial e inicie novamente.

**A ponte abre, mas não recebe bytes**

Confirme a ligação `MIDI OUT do instrumento → MIDI IN da Prelude`. Teste com
`--monitor --no-midi`. A ausência de bytes pode indicar cabo, direção da
conexão ou circuito de entrada MIDI, não necessariamente um problema no macOS.

**Não aparece no Estúdio MIDI**

A Prelude física continua sendo uma porta serial. Procure **Prelude MIDI
Bridge** na lista de entradas do aplicativo musical enquanto a ponte estiver
rodando; endpoints virtuais nem sempre aparecem como ícones de hardware no
Estúdio MIDI.

## Como funciona

```text
Instrumento MIDI OUT
        │  MIDI DIN
        ▼
Prelude antiga ── FTDI serial 31.250 baud ──► prelude-bridge
                                                   │
                                                   ▼
                                      Fonte virtual CoreMIDI
                                                   │
                                                   ▼
                                      Reaper / GarageBand / DAW
```

O parser suporta mensagens de canal, running status, System Real-Time e SysEx.
Detalhes da investigação estão em
[`docs/analise-tecnica.md`](docs/analise-tecnica.md).

## Limitações

- a ponte precisa permanecer aberta durante o uso;
- atualmente publica apenas a entrada recebida da Prelude;
- não há aplicativo gráfico, inicialização automática ou instalador assinado;
- somente uma unidade/revisão da Prelude foi validada até agora.

## Segurança e driver Windows

O desenvolvimento não executou nem incorporou o instalador Windows. O pacote
original foi usado apenas em análise estática e não faz parte deste repositório.
A solução foi implementada do zero com APIs públicas do macOS.

## Licença

[MIT](LICENSE)
