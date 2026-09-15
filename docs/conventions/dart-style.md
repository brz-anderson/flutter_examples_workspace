# Convenções de código Dart

Manual de implementação. É norma: divergência no código é bug, não preferência. O porquê de cada regra durável vive num
ADR — veja o [índice](../adr/README.md). As regras de lint que automatizam parte destas convenções estão em
[`lint-rules.md`](lint-rules.md).

## Formatação e largura de linha

A largura é configurada no `analysis_options.yaml` da raiz e vale para todo o workspace:

```yaml
formatter:
  page_width: 120
```

**Regras:**

- `dart format` **DEVE** ser executado após criar ou modificar qualquer arquivo `.dart`, aplicando somente aos arquivos
  modificados no comando atual.
- Com o `page_width` no `analysis_options.yaml`, `dart format <arquivo>` já usa 120 colunas. Para forçar em um comando
  avulso, a flag é `--page-width=120` (`--line-length` ainda é aceito, mas é o nome antigo).
- É **ESTRITAMENTE PROIBIDO** fazer commit sem passar pelo `dart format`.

## Arrow functions — regra estendida a QUALQUER função

**Arrow (`=>`) é permitida SOMENTE para retorno de uma linha sem lógica interna.** Esta regra se aplica a métodos,
funções top-level, getters, `copyWith`, builders, callbacks — qualquer função, em qualquer camada.

```dart
// ✅ CORRETO
int sum(int a, int b) => a + b;

// ❌ ERRADO — múltiplas linhas com arrow (mesmo em copyWith)
Order copyWith({String? id}) => Order(
  id: id ?? this.id,
);

// ✅ CORRETO — bloco para múltiplas linhas
Order copyWith({String? id}) {
  return Order(id: id ?? this.id);
}
```

## Imutabilidade, `const` e tipagem

- Tipo explícito **DEVE** ser declarado sempre que ele **não for óbvio** no lado direito da atribuição — retorno de
  função, resultado de `await`, valor vindo de outro pacote. Quando o tipo já está escrito ali (`'ana'`, `<String>[]`,
  `0`), anotar é ruído e o lint acusa. É o que os lints `specify_nonobvious_local_variable_types` e
  `specify_nonobvious_property_types` cobram; `always_specify_types` e `omit_local_variable_types`, os dois extremos,
  ficam desligados de propósito.
- Toda classe de modelo (entidade, Model, State, Failure) **DEVE** ter construtor `const` e todos os campos `final`.
- **NÃO use Freezed.** Implemente `copyWith` manualmente, preservando a imutabilidade.

O racional é que num monorepo o tipo inferido de um retorno atravessa fronteira de pacote sem aparecer em lugar nenhum
do código que o consome — quem lê a chamada não tem como saber o que recebeu sem abrir a implementação. Anotado, a
assinatura passa a ser o contrato. Onde o tipo já é visível, essa troca não existe, e por isso a anotação não é cobrada.

```dart
// ✅ Correto — óbvio à direita, sem anotação
final name = 'ana';
final items = <String>[];

// ✅ Correto — o tipo vem de uma chamada, então é anotado
final ColorScheme scheme = Theme.of(context).colorScheme;
final Result<Order, OrderFailure> result = await repository.findById(id);
```

## Espaçamento entre fields de classe e members de interface

- **DEVE haver exatamente uma linha em branco entre cada field de classe** e entre o último field e o primeiro método.
- Esta regra também se aplica a **interfaces**: uma linha em branco entre cada método/getter.

## Nomes de arquivo e de classe

Arquivo em `snake_case`, classe em `UpperCamelCase`. Além disso:

| Artefato                      | Classe                          | Arquivo                                          |
| :---------------------------- | :------------------------------ | :----------------------------------------------- |
| Contrato de repositório       | `AuthRepository`                | `domain/repositories/auth_repository.dart`       |
| Implementação do repositório  | `AuthRepositoryImpl`            | `data/repositories/auth_repository.dart`         |
| Fonte de dado remota          | `AuthRemote`                    | `data/datasources/auth_remote.dart`              |
| Fonte de dado local           | `AuthStorage`                   | `data/datasources/auth_storage.dart`             |
| Model com `fromJson`/`toJson` | `UserModel`                     | `data/models/user_model.dart`                    |
| Página                        | `HomePage`                      | `presentation/pages/home_page.dart`              |
| Dialog                        | `ConfirmDialog`                 | `presentation/overlays/confirm_dialog.dart`      |
| Bottom sheet                  | `FilterBottomSheet`             | `presentation/overlays/filter_bottom_sheet.dart` |
| Widget privado de uma página  | `_HomeHeader`, no mesmo arquivo | — (`widgets/` só a partir de 2 usos)             |

**Regras:**

- **O arquivo da implementação conserva o nome do contrato.** Só a **classe** recebe o sufixo `Impl`; o sufixo `_impl`
  em nome de arquivo é **PROIBIDO**. O diretório já distingue `domain/` de `data/`, e repetir isso no nome é
  redundância.
- É **PROIBIDO** `Datasource` ou `DataSource` em nome de classe ou de arquivo. O diretório `data/datasources/` é a única
  ocorrência permitida do termo; a classe usa o sufixo `Remote` ou `Storage`, que diz de onde o dado vem.
- É **PROIBIDO** o prefixo `I` em interface — `AuthRepository`, não `IAuthRepository`.
- É **PROIBIDO** nome de arquivo começando com `_`. A privacidade em Dart é do símbolo, não do arquivo; um arquivo
  privado é uma convenção de outra linguagem trazida por engano.
- `overlays/` agrupa o que sobrepõe a tela sem ser rota navegável (dialog e bottom sheet). `pages/` contém só tela
  completa associada a uma rota.

O que dessas regras dá para verificar por ferramenta está no `./tool/check_topology.sh`, que **DEVE** passar antes de
abrir pull request.

## Imports e organização

```dart
// Ordem obrigatória:
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Pacotes do monorepo
import 'package:example_auth/example_auth.dart';
import 'package:example_di/example_di.dart';
import 'package:example_logger/example_logger.dart';
import 'package:example_router/example_router.dart';

// Imports relativos ao próprio pacote
import '../domain/entities/user.dart';
import 'viewmodels/auth_bloc.dart';
```

## Logging estruturado

- É **ESTRITAMENTE PROIBIDO** usar `print()` ou `debugPrint()` em produção.
- `Logger` deve ser importado de `example_logger` e injetado via construtor em qualquer camada que precise logar.
- A instância global de `Logger` **DEVE** ser criada uma única vez em `apps/<app>/lib/bootstrap.dart` e registrada no
  container de injeção.
- Integração com serviço de crash report é feita **exclusivamente** dentro de `example_logger/lib/src/observers/` —
  nunca chamada manualmente espalhada pelo código.

**Convenção de níveis:**

- `logger.info()` — eventos informativos
- `logger.warning()` — algo inesperado mas recuperável
- `logger.error(message, error, stackTrace)` — erro técnico tratado; o observer de crash report dispara automaticamente
- `logger.critical(message, error, stackTrace)` — erro não tratado ou crash iminente

## Comentários e Dart Doc

- Comentários e Dart Doc SEMPRE em português do Brasil.
- Toda API pública **DEVE** ser documentada com `///`, explicando responsabilidade, intenção ou restrição — reforçado
  pelo lint `public_member_api_docs`.
- É **PROIBIDO** comentário que repete literalmente o que o código diz.
- Comentários `//` são reservados a fluxos extremamente complexos.

## Testabilidade de validadores, utilitários e helpers

Toda classe consumida por outra camada **DEVE** ser substituível em teste. Isso vale para validadores, utilitários,
extensões com estado, adapters, formatadores e qualquer helper que outra classe chame.

**Padrão preferencial — instância injetada.** Declare um contrato e receba a implementação por construtor. Isso é o
suficiente para `mocktail` e não exige nenhum recurso especial:

```dart
// ✅ PREFERENCIAL — mockável sem nenhum artifício
final class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc({required Validator<String> emailValidator}) : _emailValidator = emailValidator, super(...);

  final Validator<String> _emailValidator;
}
```

```dart
// no teste
class MockEmailValidator extends Mock implements Validator<String> {}
```

**Exceção — API estática.** Quando a classe é legitimamente estática — porque é chamada de um `Value Object`, de um
`copyWith` ou de qualquer ponto sem construtor onde injetar —, ela **DEVE** expor um ponto de substituição explícito e
anotado, e o teste **DEVE** desfazê-lo no `tearDown`.

```dart
final class EmailValidator implements Validator<String> {
  const EmailValidator();

  static Validator<String> _instance = const EmailValidator();

  /// Instância corrente. Produção sempre usa a implementação real.
  static Validator<String> get instance => _instance;

  /// Substitui a instância por um dublê. **Exclusivo para testes.**
  @visibleForTesting
  static void mock(Validator<String> replacement) {
    _instance = replacement;
  }

  /// Restaura a implementação real. **DEVE** ser chamado no `tearDown`.
  @visibleForTesting
  static void resetMock() {
    _instance = const EmailValidator();
  }

  @override
  ValidationResult validate(String value) { /* ... */ }
}
```

**Regras:**

- Toda classe com API estática substituível **DEVE** oferecer o par `mock` e `resetMock`, ambos anotados com
  `@visibleForTesting`. Oferecer só o `mock` é **PROIBIDO**: sem o `resetMock`, um teste vaza estado para o seguinte e a
  suíte passa a depender da ordem de execução.
- É **ESTRITAMENTE PROIBIDO** chamar `mock` ou `resetMock` em código de produção. A anotação `@visibleForTesting` faz o
  analisador acusar a violação.
- É **PROIBIDO** criar API estática apenas para evitar injeção. A estática é exceção, não conveniência: se existe um
  construtor onde a dependência caberia, use-o.
- O par `mock`/`resetMock` **NÃO** substitui a interface. A classe continua implementando seu contrato, para que o dublê
  seja um `Mock` comum de `mocktail` e não uma subclasse improvisada.
