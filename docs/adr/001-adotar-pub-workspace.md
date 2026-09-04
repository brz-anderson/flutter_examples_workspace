# ADR-001: Adotar pub workspace nativo para o monorepo

- **Status:** Aceito
- **Data:** 2026-08-26
- **Decisores:** Anderson Pereira Brzezinski (brz.anderson.pereira@gmail.com)

## Contexto

O repositório nasceu vazio: apenas um `.gitignore` e o template de ADR. Ele precisa hospedar duas coisas ao mesmo
tempo, e é essa dupla função que determina a estrutura:

- **Laboratório de arquitetura** — camadas de verdade (domínio, design, infraestrutura) exercitadas como pacotes
  separados, para que os limites entre elas sejam verificados pelo compilador e não pela disciplina de quem escreve.
- **Catálogo de exemplos** — aplicações executáveis que demonstram padrões, e que precisam compartilhar código entre
  si sem duplicação.

Um único pacote não atende ao primeiro ponto: dentro de um `lib/` só existe a fronteira que a boa vontade impuser.
Vários repositórios não atendem ao segundo: compartilhar código passaria a exigir publicação ou dependência por git.

As restrições reais no momento da decisão:

- Toolchain instalada: Flutter 3.47.1 / Dart 3.13.1. Pub workspaces existem nativamente desde o Dart 3.6, e globs na
  lista de membros desde *Dart SDK* 3.11 — ambos disponíveis.
- O `.gitignore` herdado é cópia do gitignore do **repositório do Flutter**, não de um projeto Flutter. Sua linha 3,
  `*.lock`, ignora o `pubspec.lock`. Num workspace existe um único lock, na raiz, e ele precisa ser versionado.
- O repositório não tem código Dart algum. A decisão é tomada agora, antes de existir o primeiro pacote, justamente
  porque converter uma árvore já povoada custa muito mais.

## Decisão

O repositório é um **pub workspace nativo do Dart**, sem ferramenta de monorepo externa. As regras abaixo valem para
todo pacote criado aqui:

1. O `pubspec.yaml` da raiz declara `environment: sdk: ^3.13.0` e lista os membros por glob — `apps/**` e
   `packages/**`. O glob dispensa registrar cada pacote manualmente: criar o diretório com um `pubspec.yaml` é
   suficiente para ele entrar na resolução. Um glob só pode estar declarado enquanto casar ao menos um pacote, de modo
   que cada um dos dois entra no dia em que a pasta correspondente ganha seu primeiro membro.
2. Todo membro declara `resolution: workspace` e `publish_to: none`. Nenhum pacote deste repositório vai para o
   pub.dev.
3. `apps/` contém aplicações executáveis — a vertente catálogo. `packages/` contém bibliotecas, agrupadas por camada
   em `core/` (Dart puro, sem dependência do Flutter), `design/` (widgets sem regra de negócio) e `features/` (uma
   vertical de funcionalidade cada).
4. A dependência flui em uma direção só: `apps/` → `features/` → `design/` → `core/`. O caminho inverso é proibido.
5. Pacotes internos usam o prefixo `example_` no nome: `example_result`, `example_design_system`, `example_counter`.
6. O `pubspec.lock` da raiz é versionado, e o `.gitignore` herdado do repositório do Flutter é substituído por um
   escrito para este workspace.

## Consequências

### Positivas

- Resolução única: um `pubspec.lock` e um `.dart_tool/` na raiz. É impossível dois pacotes do repositório resolverem
  versões diferentes da mesma dependência, que é a classe de bug mais cara de um monorepo Dart.
- `flutter pub get` na raiz basta para a árvore inteira, em vez de um comando por pacote.
- A direção de dependência entre camadas passa a ser verificada na compilação: `example_result`, em `core/`, não
  consegue importar um widget porque nem sequer declara o Flutter como dependência.
- Criar um pacote não exige editar nenhum arquivo existente — o glob absorve. Isso remove a fonte mais comum de
  conflito de merge em monorepos: todo mundo editando a mesma lista de membros. A exceção é o primeiro pacote de cada
  pasta, uma vez só na vida do repositório.
- Zero dependência de ferramenta externa para a resolução, então não há uma segunda ferramenta para manter compatível
  a cada upgrade do Flutter.

### Negativas

- **Não há orquestração de tarefas.** Rodar `dart test` ou `dart analyze` em todos os pacotes exige um script próprio;
  o pub não oferece o equivalente a `melos run`. Enquanto o repositório for pequeno isso se resolve com um `for` no
  shell, mas é um custo que cresce com o número de pacotes.
- **Não há versionamento nem changelog automatizados.** Como nada é publicado, hoje isso não dói; se algum pacote
  precisar sair para o pub.dev, a decisão terá de ser revista.
- **Piso de SDK alto.** O glob na lista de membros exige *language version* 3.11 no mínimo, e fixamos `^3.13.0` para
  alinhar com o Flutter 3.47.1. Quem estiver em um Dart anterior não consegue nem resolver o workspace.
- **Uma resolução compartilhada é também uma restrição compartilhada.** Dois pacotes que precisem de versões
  incompatíveis da mesma dependência não podem coexistir no workspace — um deles teria de sair dele.
- O agrupamento por camada em `packages/` obriga a classificar um pacote no momento em que ele é criado, que é
  exatamente quando menos se sabe sobre ele. Reclassificar depois é um `git mv`, barato, mas não é grátis.
- **Glob que não casa nada é erro fatal**, não aviso: `dart pub get` aborta com `No workspace packages matching`, e
  basta um dos globs estar vazio para derrubar a resolução inteira. Enquanto o repositório não tiver pacote algum, a
  lista de membros precisa ficar vazia e os globs comentados, o que cria um passo manual — descomentar — exatamente
  uma vez por pasta. É pouco, mas é um passo que a documentação tem de carregar para sempre.

## Alternativas rejeitadas

### Melos

Melos resolve justamente as duas lacunas admitidas acima — orquestração de tarefas e versionamento — e foi a resposta
padrão para monorepos Dart durante anos. Foi rejeitado porque, desde que o pub ganhou workspaces, o Melos deixou de
ser necessário para a parte difícil (resolução coerente) e passou a ser usado sobretudo como executor de scripts.
Pagar uma dependência de ferramenta, um arquivo de configuração e um acoplamento a mais a cada upgrade do Flutter
para ganhar um executor de scripts não se justifica em um repositório que hoje tem zero pacotes. A porta fica aberta:
adotar Melos depois é aditivo, porque ele reconhece o workspace nativo e conviveria com ele sem desmontar nada.

### Um único pacote Flutter com os exemplos em `lib/`

É a opção mais simples de montar e a que exige menos cerimônia por exemplo novo. Foi rejeitada porque destrói a
vertente laboratório: dentro de um mesmo pacote, qualquer arquivo importa qualquer outro, então a separação entre
domínio, design e infraestrutura vira convenção de pastas que nada impede de violar. Como o objetivo declarado é
validar decisões de arquitetura, usar uma estrutura incapaz de reprovar uma violação anula o propósito.

### Um repositório por exemplo

Dá isolamento perfeito e histórico limpo por exemplo. Foi rejeitada pelo custo do compartilhamento: qualquer código
comum — um design system, um utilitário de resultado — teria de ser publicado no pub.dev ou consumido por dependência
de git com commit fixado, e cada mudança nele viraria uma rodada de bump em N repositórios. Para um catálogo cujo
valor está justamente em comparar exemplos lado a lado, o atrito de navegar entre repositórios também pesa contra.

### Path dependencies sem workspace

Era como se fazia antes do Dart 3.6 e continua funcionando: cada pacote declara `path: ../outro`. Foi rejeitada porque
mantém uma resolução independente por pacote — um `pubspec.lock` e um `.dart_tool/` em cada um — e é exatamente aí que
nasce a divergência silenciosa de versões transitivas entre pacotes do mesmo repositório. Sendo o workspace nativo
capaz de eliminar essa classe inteira de problema sem custo, escolher a forma antiga só se justificaria por um piso de
SDK que não temos.

### Layout plano em `packages/`

Manter `packages/<nome>/` sem subpastas, deixando o agrupamento apenas no nome do pacote, é mais simples e adia a
escolha de taxonomia para quando houver o que taxonomizar. Foi rejeitada porque a árvore de diretórios é o primeiro
documento que alguém lê ao abrir o repositório, e num laboratório de arquitetura ela deve comunicar as camadas sem
exigir leitura de ADR. O custo dessa escolha está registrado nas consequências negativas, e o glob `packages/**` faz
com que voltar ao layout plano seja um `git mv` sem alteração de pubspec.

## Quando revisitar

- Se algum pacote precisar ser publicado no pub.dev: a falta de versionamento e changelog deixa de ser aceitável e o
  Melos volta à mesa.
- Se o script próprio de orquestração passar de trivial — mais de uma dezena de linhas, ou lógica de dependência entre
  tarefas —, o custo do Melos já foi pago em outra moeda.
- Se dois pacotes precisarem de versões incompatíveis da mesma dependência: a resolução única deixa de ser uma
  vantagem e passa a ser o bloqueio.
- Se `packages/` passar de três camadas, ou se um pacote for reclassificado mais de uma vez, a taxonomia por diretório
  está errada e o layout plano deve ser reconsiderado.
