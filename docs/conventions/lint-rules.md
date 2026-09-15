# Regras de lint

Manual de implementação da análise estática. A configuração em vigor é o
[`analysis_options.yaml`](../../analysis_options.yaml) da raiz — ele é a fonte, este documento é o racional. Quando os
dois divergirem, o arquivo prevalece e este texto deve ser corrigido.

Aqui estão **apenas as regras que valem para este workspace**: as que o `analysis_options.yaml` ativa, as que ele
desliga de propósito, e aquelas herdadas de `package:flutter_lints/flutter.yaml` que alguma convenção referencia
diretamente. Não é um catálogo do Dart e do Flutter — regra que não muda decisão aqui não está neste arquivo.

## A configuração é única e vive na raiz

O analisador resolve o `analysis_options.yaml` subindo os diretórios, então um único arquivo na raiz cobre todo o
workspace. `analysis_options.yaml` dentro de pacote, app ou exemplo é **PROIBIDO**, **mesmo reduzido a um `include:`**:
um arquivo local é um lugar a mais onde alguém pode relaxar uma regra sem que a revisão perceba.

`package:flutter_lints` publica um único ruleset — `package:flutter_lints/flutter.yaml` —, que já traz internamente as
regras básicas da linguagem. É o único `include` permitido.

O gerador do `dart create` e do `flutter create` escreve um `analysis_options.yaml` e um
`dev_dependencies: flutter_lints` no pacote novo. Os dois **DEVEM** ser removidos logo depois de criar o pacote — ver o
passo 2 da [convenção de pacotes](packages.md#depois-de-criar-em-qualquer-caso).

## Modo strict do analisador

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
```

Os três desligam as conversões que o Dart normalmente faz em silêncio a partir de `dynamic`. É o que torna viável
desligar `always_specify_types` sem perder segurança de tipo: em vez de exigir anotação em toda parte, o analisador
recusa o ponto em que o tipo de fato se perdeu.

- **`strict-casts`** — `dynamic` não vira outro tipo sozinho; o cast tem que ser escrito.
- **`strict-inference`** — quando a inferência não chega a nada melhor que `dynamic`, é erro, não silêncio.
- **`strict-raw-types`** — `List` sem argumento de tipo é erro; escreva `List<String>`.

```dart
// ❌ Errado — com strict-casts, o valor de um mapa dinâmico não vira String de graça
final Map<String, dynamic> json = decode(body);
final String name = json['name'];

// ✅ Correto — o cast é explícito e aparece no diff
final String name = json['name'] as String;
```

## Diagnósticos promovidos a erro

```yaml
analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    body_might_complete_normally_nullable: error
    implementation_imports: error
    unawaited_futures: error
    invalid_annotation_target: ignore
    todo: ignore
```

Promover a `error` é o que separa o aviso que se acumula do que **DEVE** travar. Os cinco primeiros descrevem código que
já está errado — falta argumento obrigatório, falta retorno, um caminho devolve `null` sem que a assinatura diga, um
pacote furou o `src/` de outro, um `Future` ficou solto.

Os dois `ignore` são deliberados: `invalid_annotation_target` dispara em falso com geração de código, e `todo` como
aviso só serve para treinar quem lê a saída a ignorá-la.

---

# Parte 1 — Escolhas deliberadas do workspace

Regras ativadas explicitamente. São as que definem o estilo daqui e as que aparecem com mais frequência em revisão.

## 1. Tipagem — `specify_nonobvious_*`, não `always_specify_types`

```yaml
always_specify_types: false
omit_local_variable_types: false
omit_obvious_property_types: false
specify_nonobvious_local_variable_types: true
specify_nonobvious_property_types: true
```

O tipo **DEVE** aparecer quando não é óbvio no lado direito da atribuição, e é opcional quando é. A anotação existe para
quem lê a chamada sem abrir a implementação — repeti-la ao lado de um literal não informa nada e só ocupa linha.

O par `always_specify_types` / `omit_local_variable_types` é o extremo de cada lado, e os dois ficam desligados de
propósito: um obriga a anotar `final String name = 'ana'`, o outro proíbe anotar o retorno opaco de uma função. A
combinação `specify_nonobvious_*` é a que cobra exatamente onde falta informação.

O ganho aparece na fronteira de pacote: um retorno inferido atravessa a fronteira sem aparecer em lugar nenhum do código
que o consome. Anotado, a assinatura passa a ser o contrato.

```dart
// ✅ Correto — o tipo é óbvio pelo literal, anotar seria ruído
final name = 'ana';
final items = <String>[];
var total = 0;

// ❌ Errado — o tipo vem de uma chamada, e quem lê não tem como saber o que recebeu
final scheme = Theme.of(context).colorScheme;
final result = await repository.findById(id);

// ✅ Correto
final ColorScheme scheme = Theme.of(context).colorScheme;
final Result<Order, OrderFailure> result = await repository.findById(id);
```

## 2. `public_member_api_docs` e `comment_references`

Toda API pública exige Dart Doc com `///`, **sempre em português do Brasil**, explicando responsabilidade, intenção ou
restrição — nunca repetindo o que o nome já diz. O `comment_references` completa a regra: um `[Símbolo]` citado no doc
tem que existir e estar no escopo, senão o link nasce quebrado.

```dart
// ❌ Errado — repete o nome, sem agregar
/// Repositório de autenticação.
abstract interface class AuthRepository {
  /// Faz sign in com e-mail.
  FutureResult<Session, AuthFailure> signInWithEmail(Email email, Password password);
}

// ✅ Correto — explica contrato e falha possível
/// Contrato de autenticação da sessão do usuário.
abstract interface class AuthRepository {
  /// Autentica o usuário e devolve a sessão ativa.
  ///
  /// Falha com [AuthInvalidCredentials] quando o par não confere e com
  /// [AuthNetworkFailure] quando o backend está inacessível.
  FutureResult<Session, AuthFailure> signInWithEmail(Email email, Password password);
}
```

## 3. `avoid_catches_without_on_clauses`

`catch` sempre com cláusula `on`. Capturar tudo esconde erro de programação — um `NoSuchMethodError` vira "falha de
rede" e o bug some do relatório.

A única exceção legítima é o handler global de erros do `bootstrap.dart`, que existe justamente para pegar o que ninguém
pegou. A conversão de exceção técnica em `Failure` acontece no repositório, sempre com o tipo declarado.

```dart
// ❌ Errado — engole qualquer erro, inclusive bug de código
try {
  final OrderModel model = await _remote.fetchOrder(id);
  return Success<Order, OrderFailure>(model.toEntity());
} catch (e) {
  return const Failure<Order, OrderFailure>(OrderConnectionFailure());
}

// ✅ Correto — cada exceção técnica vira uma falha de negócio específica
try {
  final OrderModel model = await _remote.fetchOrder(id);
  return Success<Order, OrderFailure>(model.toEntity());
} on NotFoundException {
  return Failure<Order, OrderFailure>(OrderNotFound(id));
} on HttpException catch (error, stackTrace) {
  _logger.error('Erro de rede ao buscar pedido $id', error, stackTrace);
  return const Failure<Order, OrderFailure>(OrderConnectionFailure());
}
```

## 4. `avoid_print`

O lint proíbe `print()`. **A convenção daqui é mais estrita:** `debugPrint()` também é **PROIBIDO**. Todo logging passa
pela interface `Logger`, injetada por construtor — ver
[`dart-style.md` → Logging estruturado](dart-style.md#logging-estruturado).

```dart
// ❌ Errado
print('Buscando pedido $id');
debugPrint('Buscando pedido $id');

// ✅ Correto
final class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote, this._logger);

  final OrderRemote _remote;

  final Logger _logger;

  void _trace(String id) {
    _logger.info('Buscando pedido $id');
  }
}
```

## 5. `sort_constructors_first`

O construtor vem antes dos fields e dos métodos. A leitura fica previsível: primeiro como se constrói, depois o que se
guarda, por último o que se faz. Combina com a regra de espaçamento do
[`dart-style.md`](dart-style.md#espaçamento-entre-fields-de-classe-e-members-de-interface) — exatamente uma linha em
branco entre cada field.

```dart
// ✅ Correto
final class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._remote, this._logger);

  final OrderRemote _remote;

  final Logger _logger;

  @override
  FutureResult<Order, OrderFailure> findById(String id) async { /* ... */ }
}
```

## 6. Imutabilidade — `prefer_final_*`, `prefer_const_*` e vizinhas

```yaml
prefer_final_locals: true
prefer_final_in_for_each: true
prefer_const_constructors: true
prefer_const_constructors_in_immutables: true
prefer_const_declarations: true
prefer_const_literals_to_create_immutables: true
avoid_field_initializers_in_const_classes: true
avoid_equals_and_hash_code_on_mutable_classes: true
```

Local e field que não são reatribuídos **DEVEM** ser `final`; o que dá para resolver em tempo de compilação **DEVE** ser
`const`. É o mesmo princípio que o [`dart-style.md`](dart-style.md#imutabilidade-const-e-tipagem) impõe às classes de
modelo — entidade, Model, State e Failure com construtor `const` e campos `final`.

As duas últimas fecham as saídas laterais: inicializador de field numa classe `const` deveria ser um valor `const`, e
`==`/`hashCode` sobre classe mutável produz o bug de coleção mais difícil de achar que existe — o objeto muda depois de
entrar no `Set` e some de dentro dele.

```dart
// ❌ Errado
String name = user.displayName;
return name.toUpperCase();

// ✅ Correto
final String name = user.displayName;
return name.toUpperCase();
```

## 7. `require_trailing_commas`

Vírgula final obrigatória em lista de argumentos e de parâmetros multilinha. O ganho é o diff: acrescentar um argumento
altera uma linha, não duas. Também estabiliza a saída do `dart format`.

```dart
// ❌ Errado
return Order(
  id: id,
  total: total
);

// ✅ Correto
return Order(
  id: id,
  total: total,
);
```

## 8. Assíncrono — `unawaited_futures`, `await_only_futures`, `avoid_void_async`

`Future` cujo resultado é descartado **DEVE** ser marcado com `unawaited`. Sem isso, uma falha assíncrona vira erro não
tratado e some do relatório de crash. A regra está promovida a **erro** na seção `analyzer.errors`.

`avoid_void_async` proíbe `void` em função `async` fora de callback de evento: `void` não dá para aguardar nem para
capturar a falha. `await_only_futures` acusa o `await` sobre valor que não é `Future` — quase sempre sinal de que a
assinatura mudou e a chamada não acompanhou.

`discarded_futures` fica **desligado**: ele acusa qualquer `Future` criado fora de contexto assíncrono, o que cobre
demais e conflita com o uso legítimo de `unawaited`.

```dart
// ❌ Errado — se falhar, ninguém fica sabendo
_analytics.logEvent('order_placed');

// ✅ Correto — a intenção de não aguardar fica explícita
unawaited(_analytics.logEvent('order_placed'));

// ✅ Correto — ou simplesmente aguarde
await _analytics.logEvent('order_placed');
```

## 9. `only_throw_errors`, `avoid_catching_errors` e `throw_in_finally`

Só lance objetos que sejam `Exception` ou `Error`, e nunca capture `Error` — `Error` sinaliza bug de programação, que
**DEVE** derrubar e ser reportado, não ser tratado. `throw_in_finally` proíbe lançar dentro do `finally`, que descarta a
exceção original e apaga a causa real.

Isso sustenta o modelo de erro do workspace: `throw` **não** é fluxo de controle entre camadas. Falha de negócio é uma
`Failure` retornada dentro de `Result`.

```dart
// ❌ Errado
if (order.total <= 0) throw 'Total inválido';

// ✅ Correto
if (order.total <= 0) return const Failure<Order, OrderFailure>(OrderUnavailable());
```

## 10. Imports — `directives_ordering`, `prefer_relative_imports`, `combinators_ordering`

A ordem é a fixada em [`dart-style.md`](dart-style.md#imports-e-organização): `dart:`, pacotes externos, pacotes do
workspace e, por último, relativos ao próprio pacote.

`prefer_relative_imports` cobra o último grupo: dentro do mesmo pacote o import é **relativo**, nunca
`package:example_x/src/...`. Um caminho absoluto para dentro do próprio pacote é o mesmo arquivo importado por dois
nomes, e o analisador passa a tratá-lo como dois tipos distintos.

```dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:example_auth/example_auth.dart';
import 'package:example_router/example_router.dart';

import '../domain/entities/user.dart';
```

## 11. `avoid_dynamic_calls` e `library_private_types_in_public_api`

`avoid_dynamic_calls` proíbe chamar método sobre `dynamic` — o erro sairia em tempo de execução, e sempre longe de onde
o tipo se perdeu. Junto com `strict-casts`, ele empurra a desserialização para o Model, que é onde o `as` **DEVE**
acontecer.

`library_private_types_in_public_api` impede que um tipo privado vaze em assinatura pública: o consumidor consegue
chamar o método e não consegue nomear o que recebeu.

## 12. Demais regras ativadas

Ativadas pelo mesmo motivo — consistência mecânica, verificável em revisão — e sem particularidade que exija exemplo:

| Regra                                   | Efeito                                                            |
| :-------------------------------------- | :---------------------------------------------------------------- |
| `always_declare_return_types`           | Todo método declara o tipo de retorno                             |
| `type_annotate_public_apis`             | API pública sempre anotada                                        |
| `cast_nullable_to_non_nullable`         | Proíbe cast que esconde nulo                                      |
| `avoid_positional_boolean_parameters`   | `bool` posicional vira parâmetro nomeado, que é legível           |
| `avoid_setters_without_getters`         | Setter sozinho esconde estado que ninguém consegue ler            |
| `prefer_single_quotes`                  | Aspas simples como padrão                                         |
| `avoid_multiple_declarations_per_line`  | Uma declaração por linha, para o diff apontar a certa             |
| `sort_pub_dependencies`                 | Dependências em ordem alfabética, o que elimina conflito de merge |
| `unnecessary_lambdas`                   | `(x) => f(x)` vira `f` — tear-off em vez de closure               |
| `unnecessary_parenthesis`               | Parêntese que não muda precedência sai                            |
| `cancel_subscriptions`                  | `StreamSubscription` sempre cancelada                             |
| `close_sinks`                           | `StreamController` sempre fechado — relevante em Bloc             |
| `test_types_in_equals`                  | `==` confere o tipo antes de comparar campo                       |
| `use_colored_box` / `use_decorated_box` | `Container` só de cor ou de decoração vira o widget específico    |

## 13. Regras desligadas de propósito

| Regra                         | Por que fica desligada                                                     |
| :---------------------------- | :------------------------------------------------------------------------- |
| `always_specify_types`        | Extremo oposto; `specify_nonobvious_*` cobra só onde falta informação      |
| `omit_local_variable_types`   | Proibiria anotar retorno opaco, que é justamente onde a anotação vale      |
| `omit_obvious_property_types` | Mesma razão, aplicada a propriedade                                        |
| `prefer_initializing_formals` | Conflita com `sort_constructors_first` em construtor `const` com validação |
| `discarded_futures`           | Cobre demais e conflita com o uso legítimo de `unawaited`                  |
| `cascade_invocations`         | Cascata forçada piora a leitura em código de construção de widget          |
| `lines_longer_than_80_chars`  | A largura daqui é 120, garantida pelo `formatter.page_width`               |

---

# Parte 2 — Regras herdadas que as convenções normatizam

Vêm de `package:flutter_lints/flutter.yaml`. Estão aqui porque alguma convenção as referencia diretamente, ou porque o
comportamento esperado não é óbvio.

## 14. `use_build_context_synchronously`

Não use `BuildContext` depois de um `await` sem checar `context.mounted`. Passado o salto assíncrono, o widget pode já
ter saído da árvore, e usar o contexto morto gera exceção.

```dart
// ✅ Correto
Future<void> _submit(BuildContext context) async {
  await _bloc.save();

  if (!context.mounted) return;

  Navigator.of(context).pop();
}
```

## 15. `use_key_in_widget_constructors`

Todo widget público aceita `Key`. O Flutter usa a chave para preservar estado ao reordenar elementos de uma lista.

```dart
// ✅ Correto
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order});

  final Order order;
}
```

## 16. `prefer_const_constructors_in_immutables`

Widget com todos os campos `final` **DEVE** expor construtor `const`. Instância constante é reaproveitada e evita
reconstruir a subárvore.

Atenção à interação com `Theme.of(context)`: se manter o `const` obrigar a ler um valor literal em vez de perguntar ao
tema, **abra mão do `const`**. Um componente cego ao tema custa muito mais que uma alocação.

## 17. `sized_box_for_whitespace`, `avoid_unnecessary_containers`, `use_colored_box`, `use_decorated_box`

Para espaçamento use `SizedBox`, que é mais leve que `Container`; não envolva widget em `Container` sem nenhuma
propriedade de configuração ativa; e `Container` que só pinta cor ou só aplica decoração vira `ColoredBox` ou
`DecoratedBox`.

O valor do espaçamento vem do token do design system, nunca de literal numérico espalhado pela tela.

```dart
// ❌ Errado
Container(height: 16, child: null);

// ✅ Correto
SizedBox(height: AppSpacing.md);
```

## 18. `implementation_imports`

Não importe `src/` de outro pacote. É a mesma fronteira que a [convenção de pacotes](packages.md) descreve e que o
`./tool/check_topology.sh` verifica — aqui promovida a **erro** na seção `analyzer.errors`, porque um furo de `src/`
acopla a um detalhe interno que pode mudar sem aviso.

```dart
// ❌ Errado
import 'package:example_design_system/src/tokens/app_colors.dart';

// ✅ Correto
import 'package:example_design_system/example_design_system.dart';
```

## 19. `exhaustive_cases`

`switch` sobre enum cobre todos os valores. É a regra que sustenta o modelo de erro: o `switch` exaustivo sobre a
hierarquia `sealed` de `Failure` falha na compilação quando uma variante nova aparece e alguém esquece de tratá-la.

```dart
// ✅ Correto — adicionar uma variante em OrderFailure quebra aqui, e não em produção
String _messageFor(OrderFailure failure) {
  return switch (failure) {
    OrderNotFound() => 'Pedido não encontrado.',
    OrderUnavailable() => 'Pedido indisponível no momento.',
    OrderConnectionFailure() => 'Sem conexão. Tente novamente.',
  };
}
```

## 20. `annotate_overrides` e `use_super_parameters`

Todo membro sobrescrito leva `@override`; parâmetro repassado ao construtor da superclasse usa a forma curta
`super.key`.

```dart
// ✅ Correto
class OrderTile extends StatelessWidget {
  const OrderTile({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

## 21. `avoid_web_libraries_in_flutter` e `no_logic_in_create_state`

Não importe `dart:html` nem `dart:js` em código compartilhado — quebra a compilação para iOS e Android.

`createState()` não recebe argumento nem executa lógica; os dados chegam por `widget.<propriedade>`.

## 22. `use_full_hex_values_for_flutter_colors`

Cor em `0xAARRGGBB`, com os oito dígitos. Omitir o alfa gera cor transparente por acidente.

É relevante **apenas dentro do pacote de design system**, ao definir token. Em qualquer outro lugar, hexadecimal literal
é proibido — a cor vem do tema ou do token.

```dart
// ✅ Correto — e só em packages/design/design_system/lib/src/tokens/
const Color primaryBlue = Color(0xFF2196F3);
```

---

# Dependências de teste

**`mocktail`** é a biblioteca de mocking do workspace. Ela é autossuficiente e não exige geração de código nem pacote
abstrator: cada pacote a declara em `dev_dependencies` e usa direto em `test/`.

```yaml
dev_dependencies:
  mocktail: ^1.0.0
  flutter_test:
    sdk: flutter
```

A escolha por `mocktail` em vez de `mockito` é o que torna possível excluir `**/*.mocks.dart` da análise sem perder
nada: não há arquivo gerado para analisar. O padrão de classe substituível em teste está em
[`dart-style.md` → Testabilidade](dart-style.md#testabilidade-de-validadores-utilitários-e-helpers).

# Exceções

Adicionar `// ignore:` ou `// ignore_for_file:` **sem um comentário adjacente justificando** é **PROIBIDO**. Desabilitar
regra num `analysis_options.yaml` de pacote também é — e, antes disso, o arquivo local já é proibido por si.

```dart
// ✅ Correto — a exceção é auditável
// ignore: avoid_print — script de build, não roda no app
print('Gerando tokens...');
```

Quando a exceção deixar de ser pontual e virar padrão, ela não é mais exceção: ou a regra sai do `analysis_options.yaml`
com o motivo registrado, ou vira um ADR. Um `ignore` repetido em cinco arquivos é uma decisão tomada sem ninguém ter
decidido.
