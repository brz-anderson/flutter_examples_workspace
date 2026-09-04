# Convenções de pacotes

Manual de implementação do workspace. O porquê das escolhas está no
[ADR-001](../adr/001-adotar-pub-workspace.md); aqui está o como.

## Onde o pacote vive

| Diretório | Camada | Depende de |
| --- | --- | --- |
| `apps/<nome>/` | aplicação executável | qualquer pacote |
| `packages/core/<nome>/` | Dart puro, sem Flutter | só `core/` |
| `packages/design/<nome>/` | widgets sem regra de negócio | `core/` |
| `packages/features/<nome>/` | uma vertical de funcionalidade | `design/`, `core/` |

A dependência flui em uma direção só: `apps/` → `features/` → `design/` → `core/`. O caminho inverso é **proibido**.

Hoje só uma dessas fronteiras é verificada automaticamente — um pacote de `core/` não declara o Flutter, então não
consegue importar widget. As outras duas dependem de revisão.

## Nomes

Todo pacote interno usa o prefixo `example_`:

```
example_result           packages/core/result/
example_design_system    packages/design/design_system/
example_counter          packages/features/counter/
```

O nome do diretório dispensa o prefixo; o `name:` do `pubspec.yaml` não. O prefixo existe para que
`import 'package:example_result/...'` se distinga à primeira vista de um pacote do pub.dev.

## Criar um pacote

O glob `packages/**` da raiz absorve qualquer diretório novo que tenha um `pubspec.yaml` — **não é preciso registrar
o pacote**.

**Exceção, uma vez por pasta:** um glob que não casa nenhum pacote aborta a resolução com
`No workspace packages matching`. Por isso os globs nascem comentados no `pubspec.yaml` da raiz. Ao criar o
**primeiro** pacote de `apps/` ou de `packages/`, descomente o glob correspondente:

```yaml
workspace:
  - packages/**
```

Do segundo pacote em diante a raiz não é mais tocada.

### Pacote Dart puro (`core/`)

```sh
dart create --template=package packages/core/result
```

### Pacote Flutter (`design/`, `features/`)

```sh
flutter create --template=package packages/design/design_system
```

### App

```sh
flutter create --platforms=windows,android,web,ios,macos --project-name example_counter apps/counter
```

### Depois de criar, em qualquer caso

1. Ajuste o `pubspec.yaml` gerado:

   ```yaml
   name: example_result
   publish_to: none
   resolution: workspace

   environment:
     sdk: ^3.13.0
   ```

2. Remova `dev_dependencies: flutter_lints` e o `analysis_options.yaml` do pacote, se o gerador os tiver criado. Ambos
   já vêm da raiz — o analisador resolve o `analysis_options.yaml` subindo os diretórios.
3. Remova qualquer `dependency_overrides`.
4. Se o gerador criou um `pubspec.lock` no pacote, apague: num workspace o lock é único e vive na raiz.
5. Se este é o primeiro pacote de `apps/` ou de `packages/`, descomente o glob correspondente na raiz.
6. Rode `flutter pub get` **na raiz**.

## Depender de outro pacote do workspace

Sem `path:` e sem versão — `any` basta, porque a resolução do workspace aponta para o diretório local:

```yaml
dependencies:
  example_result: any
```

## Checklist de revisão

- [ ] `name:` com prefixo `example_`
- [ ] `publish_to: none` e `resolution: workspace`
- [ ] Está na camada certa, e não depende de camada mais externa
- [ ] Não tem `pubspec.lock`, `analysis_options.yaml` nem `dependency_overrides` próprios
- [ ] Se é o primeiro da pasta, o glob correspondente foi descomentado na raiz
- [ ] `dart pub get` na raiz resolve
