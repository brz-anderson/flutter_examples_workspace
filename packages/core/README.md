# packages/core/

Dart puro. **Nenhum pacote desta camada declara o Flutter como dependência** — é o que torna a fronteira verificável
em vez de opcional.

## O que entra

- Tipos e contratos de domínio: `Result`, `Failure`, value objects, entidades.
- Abstrações de infraestrutura — a interface, não a implementação que depende de plugin.
- Utilitários sem UI: formatação, validação, extensões.

## O que não entra

Qualquer coisa que importe `package:flutter/*`. Se precisa de `BuildContext`, `Widget` ou binding, o lugar é
`design/` ou `features/`.

## Dependências

Só outros pacotes de `core/`. Esta é a camada mais interna.

## Testes

Rodam com `dart test`, sem `flutter test` e sem device — é o efeito colateral mais útil de manter a camada livre do
Flutter.
