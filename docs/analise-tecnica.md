# Análise técnica

## Resumo

A E.R. Pires Prelude antiga enumera como uma interface serial FTDI, não como um
dispositivo USB-MIDI class-compliant. No hardware testado, o macOS criou uma
porta `/dev/cu.usbserial-*` para `VID 0403`, `PID 6001`.

O teste físico confirmou que a porta transporta MIDI 1.0 cru em UART 8-N-1 a
31.250 baud. Não foi necessário enviar comando proprietário de inicialização.

## Evidências observadas

- produto USB: `PRELUDE MIDI <-> USB`;
- fabricante no descritor: `ERP`;
- USB full-speed;
- porta publicada pelo driver serial do macOS;
- mensagens Note On/Off válidas no canal 10;
- running status, Control Change, Program Change, MIDI Clock (`F8`) e Active
  Sensing (`FE`).

Exemplo capturado ao tocar um pad:

```text
99 30 27  # Note On, canal 10, nota 48, velocity 39
99 30 00  # Note On com velocity zero, equivalente a Note Off
```

O par `0403:6001` é usado por dispositivos USB-UART FTDI. O descritor USB não
é suficiente para afirmar qual modelo físico do chip existe em todas as
revisões da Prelude. A família FTDI relevante suporta baud rates não padrão;
31.250 é obtido exatamente pelo divisor 96 da referência de 3 MHz.

## Arquitetura da solução

1. o driver serial já incluído no macOS expõe `/dev/cu.usbserial-*`;
2. `prelude-bridge` configura a porta em modo raw, 8-N-1, sem flow control;
3. o parser recompõe mensagens MIDI, inclusive running status e bytes realtime;
4. uma fonte virtual CoreMIDI entrega as mensagens aos aplicativos musicais.

Toda a ponte roda em user space. Ela não instala kext, DriverKit extension,
daemon ou item de inicialização.

## Investigação do driver Windows

O instalador de 64 bits disponível na página oficial da E.R. Pires foi
inspecionado apenas estaticamente. Ele é um executável PE32 criado com Astrum
InstallWizard e contém um payload em formato proprietário. O instalador não foi
executado e nenhum arquivo ou código dele foi incorporado ao projeto.

A implementação macOS foi escrita do zero. A descoberta do transporte serial
direto tornou desnecessário depender do driver Windows para o funcionamento da
ponte.

## Limitações da validação

- apenas uma unidade física da Prelude antiga foi testada;
- outras revisões podem usar descritores, EEPROM ou circuitos diferentes;
- somente o caminho MIDI IN da Prelude para o Mac foi implementado;
- SysEx longo ainda merece testes com hardware específico;
- a presença de MIDI Clock e Active Sensing depende do instrumento conectado.

Relatos de outras unidades são bem-vindos conforme
[`CONTRIBUTING.md`](../CONTRIBUTING.md).
