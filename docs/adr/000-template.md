# ADR-000: Título que enuncia a decisão

> **Título:** enuncie a decisão, não o tema — "Versionar o `pubspec.lock` da raiz", não "Sobre o lockfile". Frase
> nominal ou imperativa, tanto faz. O comprimento é o que a decisão exigir: decisão de várias partes costuma precisar de
> um título mais longo, e um título vago custa mais caro que um título comprido.

> **Como usar:** copie este arquivo para `NNN-slug-em-ingles.md` — o nome do arquivo é em inglês, em kebab-case; o
> conteúdo é em português do Brasil, quebrado em 120 colunas (`prettier --print-width 120 --prose-wrap always`, como
> todo Markdown do repositório). Numere em sequência e adicione a linha no índice do [README](README.md) no mesmo
> commit. Depois, conforme o caso:
>
> - **Decisão já tomada:** apague a seção "Variante: decisão em aberto" inteira, junto com o `---` que a separa, e todas
    >   as citações `>` deste arquivo — nesta variante, citação é sempre instrução.
> - **Decisão ainda em aberto:** use apenas o conteúdo do bloco de código de
    >   [decisão em aberto](#variante-decisão-em-aberto), sem as linhas de cerca, e descarte todo o resto. Ali é ao
    >   contrário: as citações `>` são conteúdo obrigatório do ADR e ficam; instrução é o que está em `<!-- -->`.

- **Status:** Proposto | Aceito | Substituído por ADR-XXX | Descontinuado
- **Data:** AAAA-MM-DD
- **Decisores:** Nome Completo (e-mail)

> **Substituir e descontinuar.** Nenhum dos dois status se escreve de um lado só, e valem no regime pós-publicação
> descrito no [README](README.md) — antes disso o ADR é reescrito no lugar, quando o mantenedor pedir.
>
> - **Substituição** é um ato de dois lados, no mesmo pull request. O ADR antigo troca o `Status` para
    >   `Substituído por ADR-XXX` e ganha, logo abaixo do bloco de metadados, uma nota de uma linha dizendo o que mudou; o
    >   corpo permanece intacto, porque a partir da publicação o histórico é o valor. O ADR novo abre o `## Contexto`
    >   dizendo qual ADR ele substitui e por quê. Sem os dois lados, um dos dois arquivos mente.
> - **Descontinuação** é o caso sem substituto: o `Status` vira `Descontinuado` e a mesma nota registra que fato tirou a
    >   decisão de circulação.
> - Nos dois casos, o Status muda também na linha do índice do README, no mesmo commit. O arquivo nunca é apagado nem
    >   renumerado.

## Contexto

> Qual é a força em jogo? O que motivou a decisão _agora_? Restrições reais (prazo, time, compatibilidade, compliance).
> Sem esta seção o ADR não serve para nada: quem lê no futuro precisa saber o que era verdade na época.

## Decisão

> O que foi decidido, em frases afirmativas. Escreva como regra, não como intenção.
>
> Decisão de uma parte só cabe em uma ou duas frases, sem subseção nenhuma. Quando ela tem partes que se sustentam
> separadamente — o princípio, o limite dele, a aplicação a um caso concreto —, use uma subseção `###` numerada por
> parte, cada uma abrindo pela frase-regra e só depois explicando. É o formato de metade dos ADRs em vigor, e existe
> porque parte de decisão precisa ser citável por número em revisão e no plano de migração.

## Consequências

### Positivas

- Ganho concreto, de preferência observável.

### Negativas

- Custo assumido. **Não deixe vazio** — uma decisão sem custo é sinal de que o trade-off não foi analisado.

## Alternativas rejeitadas

> Uma subseção `###` por alternativa, com o título sendo a alternativa e o corpo o motivo técnico da rejeição. **Não use
> tabela aqui:** linha de tabela é uma linha física, então o argumento inteiro teria de caber em uma linha de centenas
> de colunas — estoura o limite de 120 e torna ilegível o diff de qualquer ajuste.
>
> A primeira alternativa a considerar é o estado atual: manter o que já existe, ou não fazer nada. É a mais fácil de
> esquecer, justamente por já estar aí, e é a que o leitor futuro mais quer ver rejeitada por escrito.

### Opção A

Motivo técnico da rejeição, descrito. Diga o que ela resolveria e por que o custo não compensa — "não gostamos" não é
motivo.

### Opção B

Idem.

## Proposta de emenda ao manual

> Só quando a decisão contradiz norma já escrita num manual de [`conventions/`](../conventions/) ou no
> [`README.md`](../../README.md) da raiz. Se ela não contradiz nada, apague a seção inteira. Um ponto numerado por
> trecho a emendar, dizendo qual documento, o que está lá hoje e o que passa a valer.
>
> Quando a emenda já tiver sido aplicada no mesmo trabalho, o título vira
> `## Emenda ao manual — aplicada em AAAA-MM-DD`, o corpo relata o que foi feito, e uma linha `Falta:` no fim registra o
> que ficou pendente.

Esta seção **propõe**; não altera nada. A emenda entra em pull request próprio.

1. **`conventions/<arquivo>.md`, seção N** — o trecho que está lá hoje e o que passa a valer.

Nada disso é feito por iniciativa de quem encontrar a divergência.

## Quando revisitar

> Que fato novo tornaria esta decisão errada? Ex.: "se o time passar de 15 pessoas", "se o Dart passar a suportar X".

---

## Variante: decisão em aberto

Quando o problema e as opções candidatas já valem registro, mas a escolha ainda não foi feita, use o esqueleto abaixo no
lugar das seções `## Decisão` e `## Alternativas rejeitadas`. As demais seções do padrão (`## Contexto`) continuam
valendo.

```markdown
# ADR-NNN: Título que enuncia a decisão

- **Status:** Proposto — decisão em aberto
- **Data:** AAAA-MM-DD
- **Decisores:** Nome Completo (e-mail)

> **Bloqueio:** enquanto este ADR estiver como Proposto, é proibido introduzir [o que a decisão vai regular] por
> iniciativa própria.

<!-- Nota de vigência: só quando este ADR reabre algo já decidido. Um ADR Proposto não suspende norma em vigor, e
     precisa dizer exatamente o que continua valendo enquanto aguarda. Apague se nada estava decidido antes. -->

> **Vigência:** enquanto esta decisão estiver em aberto, continua valendo [a norma que já está em vigor], sem exceção.

## Contexto

O problema e as restrições reais — igual à variante fechada.

## Restrições inegociáveis

<!-- Condições que toda opção candidata DEVE satisfazer, independente de qual for escolhida. -->

- Restrição 1.

## Opção A — <nome>

### Estrutura

<!-- Opcional: árvore de diretórios, assinatura, diagrama. -->

### Uso

<!-- Código de exemplo. -->

### Avaliação

**A favor**

- Ponto forte.

**Contra**

- Ponto fraco.

**Risco específico**

<!-- Opcional: só quando a opção tiver um risco particular a este projeto. -->

## Opção B — <nome>

<!-- Mesma estrutura da Opção A. Uma seção por alternativa candidata. -->

## Comparativo

| Critério   | Opção A | Opção B |
| ---------- | ------- | ------- |
| Critério 1 |         |         |

## Recomendação para análise

<!-- Opcional: indicação de quem escreveu o ADR, sem forçar a decisão. -->

## Perguntas a responder antes de decidir

- O que falta saber para fechar a escolha?
```

### Ao fechar a decisão

1. `Status` muda para **Aceito**.
2. A opção escolhida vira `## Decisão`, escrita como regra — uma ou duas frases, ou uma subseção `###` numerada por
   parte quando a decisão tiver mais de uma.
3. As demais opções viram subseções `###` de `## Alternativas rejeitadas` — a `### Avaliação` de cada uma condensa no
   motivo técnico da rejeição.
4. `## Consequências` e `## Quando revisitar` passam a ser preenchidos.
5. A nota de bloqueio, a nota de vigência, `## Comparativo` e `## Perguntas a responder` são removidos.
6. `## Restrições inegociáveis` não sobrevive como seção própria: a restrição que continua valendo entra na
   `## Decisão`, como parte da regra; a que era só descrição do terreno volta para `## Contexto`. Restrição que não
   virou nenhuma das duas coisas não era inegociável.
7. A regra correspondente entra na constituição ou no manual **no mesmo pull request** — ADR aceito cuja regra não está
   na norma é decisão que ninguém cumpre. Se ela contradiz norma escrita, entra a
   `## Proposta de emenda à constituição`, que propõe sem aplicar.
8. A linha do ADR no índice do [README](README.md) muda de `Proposto` para `Aceito`.
9. O item correspondente sai de "Pendências e exceções em vigor" do README — a pendência fechou.

O arquivo inteiro migra para o formato padrão deste template.
