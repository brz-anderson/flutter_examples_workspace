# packages/

Bibliotecas do workspace, agrupadas por camada. Nenhuma é publicada: todas usam `publish_to: none` e
`resolution: workspace`.

## As três camadas

| Camada | Conteúdo | Pode depender de |
| --- | --- | --- |
| [`core/`](core/) | Dart puro — tipos, contratos, utilitários. Sem Flutter. | nada além do próprio `core/` |
| [`design/`](design/) | Widgets, tema, tokens. Sem regra de negócio. | `core/` |
| [`features/`](features/) | Uma vertical de funcionalidade por pacote. | `design/`, `core/` |

A dependência flui em uma direção só:

```
apps/ → features/ → design/ → core/
```

O caminho inverso é proibido. Parte disso o compilador já cobra sozinho: um pacote de `core/` não declara o Flutter
como dependência, então nem consegue importar um widget.

## Nomes

Prefixo `example_`, sempre: `example_result`, `example_design_system`, `example_counter`. O prefixo deixa óbvio no
import o que é interno e o que veio do pub.dev.

## Criar um pacote

O glob `packages/**` da raiz absorve qualquer diretório novo com `pubspec.yaml`, então a raiz não precisa ser
editada — **exceto no primeiro pacote**, quando o glob ainda está comentado e precisa ser habilitado.

Detalhes e checklist em [`../docs/conventions/packages.md`](../docs/conventions/packages.md); o porquê do layout está
no [ADR-001](../docs/adr/001-adotar-pub-workspace.md).
