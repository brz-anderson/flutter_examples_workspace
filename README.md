# flutter_examples_workspace

Laboratório de arquitetura e catálogo de exemplos em Flutter, organizado como um
[pub workspace](https://dart.dev/tools/pub/workspaces) nativo — sem Melos.

O repositório serve a dois propósitos ao mesmo tempo:

- **Laboratório** — as camadas são pacotes separados, então a fronteira entre elas é verificada pelo compilador e não
  pela disciplina de quem escreve.
- **Catálogo** — cada app em `apps/` é um exemplo executável, e todos compartilham código sem duplicação.

## Estrutura

```
apps/          aplicações executáveis
packages/
  core/        Dart puro, sem dependência do Flutter
  design/      widgets sem regra de negócio
  features/    uma vertical de funcionalidade por pacote
docs/
  adr/         decisões de arquitetura e o porquê delas
  conventions/ manuais de implementação
```

A dependência flui em uma direção só: `apps/` → `features/` → `design/` → `core/`.

## Como resolver

```sh
dart pub get      # enquanto não houver nenhum pacote Flutter
flutter pub get   # a partir do primeiro pacote que dependa do Flutter
```

Rode na **raiz**. A resolução é única para o workspace inteiro: um `.dart_tool/` e um `pubspec.lock`, ambos na raiz.
O `pubspec.lock` é versionado.

## Como criar um pacote

Crie o diretório sob a camada certa e escreva o `pubspec.yaml`. Não é preciso registrar o pacote na raiz — o glob
`packages/**` o absorve. A única exceção é o **primeiro** pacote de `apps/` ou de `packages/`: os globs nascem
comentados no `pubspec.yaml` raiz, porque um glob sem nenhum pacote correspondente aborta a resolução.

```yaml
name: example_result
publish_to: none
resolution: workspace

environment:
  sdk: ^3.13.0
```

Detalhes em [`docs/conventions/packages.md`](docs/conventions/packages.md).

## Requisitos

Flutter 3.47.1 / Dart 3.13.1 ou superior. O piso não é arbitrário: o glob na lista de membros do workspace exige
*language version* 3.11 no mínimo.

## Documentação

- [Decisões de arquitetura (ADR)](docs/adr/README.md)
- [Convenções de código Dart](docs/conventions/dart-style.md)
- [Convenções de pacotes](docs/conventions/packages.md)
