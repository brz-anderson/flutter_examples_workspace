# apps/

Aplicações executáveis. Cada app é um exemplo autocontido que demonstra um padrão de arquitetura, e é o único lugar
do repositório onde existe `main.dart`, composition root e configuração de plataforma.

## O que entra aqui

- Um app por exemplo, com nome descritivo do que ele demonstra (`counter_bloc`, `composition_root`).
- Toda a fiação: registro de dependências, rotas, tema, `runApp`.

## O que não entra

Regra de negócio, widget reutilizável e utilitário. Se outro app pode querer, o lugar é `packages/` — o app fica com
a composição, não com a implementação.

## Dependências

Um app pode depender de qualquer camada de `packages/`. Nada em `packages/` pode depender de um app.

## Plataformas

Todo app declara suporte a **windows, android, web, ios e macos**:

```sh
flutter create --platforms=windows,android,web,ios,macos --project-name example_app apps/example_app
```

Depois de criar, ajuste o `pubspec.yaml` gerado para `publish_to: none` e `resolution: workspace`, e remova o bloco
`dependency_overrides` se o `flutter create` tiver adicionado algum.

No **primeiro** app, descomente também o glob `apps/**` no `pubspec.yaml` da raiz — ele nasce comentado porque um
glob sem nenhum pacote correspondente aborta a resolução. Ver
[`../docs/conventions/packages.md`](../docs/conventions/packages.md).
