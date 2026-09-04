# Architecture Decision Records

Registro das decisões estruturais deste workspace. Uma decisão difícil de reverter merece um ADR — texto corrido espalhado em
README vira impossível de rastrear seis meses depois.

Um ADR documenta **por que** uma decisão foi tomada e o que foi rejeitado no caminho. A regra em si vive no manual
correspondente em [`conventions/`](../conventions/), que é imperativo e curto; o ADR guarda a justificativa, que o
manual não carrega. Quando os dois divergirem, o manual prevalece e o ADR deve ser corrigido ou superado.

## Índice

| # | Decisão | Status |
| --- | --- | --- |
| [001] | Adotar pub workspace nativo para o monorepo | Aceito |

## Quando escrever um ADR

Sempre que a decisão for **estrutural e cara de reverter**:

- gerenciamento de estado, navegação, injeção de dependência;
- modularização e fronteiras entre pacotes;
- camada de dados e contrato com o backend;
- adoção ou encapsulamento de lib externa estrutural;
- estratégia multiplataforma e código nativo.

Não escreva ADR para escolha de nome de variável, formatação ou detalhe reversível em uma tarde.

## Como escrever

Copie [`000-template.md`](000-template.md), numere em sequência e adicione a linha no índice acima — junto com a
entrada de link no rodapé deste arquivo. Siga a estrutura do template; não a reproduza aqui, para não haver duas
cópias que possam divergir.

Quando a decisão ainda **não** foi tomada, mas o problema e as opções candidatas já valem registro, use a variante
descrita no template na seção "Variante: decisão em aberto". Ela troca `## Decisão` e `## Alternativas rejeitadas` por
uma seção por opção candidata, mais `## Comparativo` e `## Perguntas a responder antes de decidir`.

**Enquanto o projeto não estiver em produção**, qualquer ADR pode ser editado livremente, inclusive os de status
`Aceito`: sem histórico, reescrever o ADR é mais barato e mais honesto que empilhar um substituto.

**A partir do lançamento**, um ADR aceito deixa de ser editado. Se a decisão mudar, escreva um novo que a substitua
e marque o antigo como `Substituído por NNN`. O histórico passa a ser o valor.

## Nomenclatura e numeração

O nome do arquivo é o número de três dígitos seguido de um slug em kebab-case: `NNN-slug-da-decisao.md`. Slug em inglês e
conteúdo em português do Brasil, como toda a documentação do repositório.

A numeração é sequencial e imutável. Escolher o próximo número é olhar o maior do índice e somar um. O
`000-template.md` não é ADR e não ocupa lugar na sequência.

Um ADR nunca é renumerado nem excluído: decisão revertida vira um ADR novo que supera o anterior. A única exceção é
renumeração ou exclusão pedida explicitamente pelo mantenedor, e nesse caso o pedido fica registrado no corpo do
commit que a executa.

## Status possíveis

| Status | Significado |
| --- | --- |
| Proposto | Em avaliação. Nenhum código pode assumir o resultado de uma decisão ainda em aberto |
| Aceito | Em vigor. A regra correspondente vale, e divergência no código é bug |
| Substituído por NNN | Superado por um ADR posterior. O arquivo permanece, para preservar o histórico |
| Descontinuado | Deixou de ser relevante, sem substituto |

Um ADR `Proposto` **não suspende norma que já esteja em vigor**. Se ele for reabrir algo já decidido, deve trazer no
topo uma nota de vigência dizendo exatamente o que continua valendo enquanto a decisão aguarda confirmação.

[001]: 001-adotar-pub-workspace.md
