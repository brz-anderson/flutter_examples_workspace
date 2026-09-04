# ADR-000: Título curto no imperativo

> **Como usar:** copie este arquivo para `NNN-slug-da-decisao.md`, numere em sequência, adicione a linha no índice do
> [README](README.md) e apague todas as linhas de instrução (as citações `>`). Se a decisão ainda **não** foi tomada,
> use o esqueleto de [decisão em aberto](#variante-decisão-em-aberto) no fim deste arquivo.

- **Status:** Proposto | Aceito | Substituído por ADR-XXX | Descontinuado
- **Data:** AAAA-MM-DD
- **Decisores:** Nome Completo (@handle)

## Contexto

> Qual é a força em jogo? O que motivou a decisão _agora_? Restrições reais (prazo, time, compatibilidade, compliance).
> Sem esta seção o ADR não serve para nada: quem lê no futuro precisa saber o que era verdade na época.

## Decisão

> O que foi decidido, em uma ou duas frases afirmativas. Escreva como regra, não como intenção.

## Consequências

### Positivas

- Ganho concreto, de preferência observável.

### Negativas

- Custo assumido. **Não deixe vazio** — uma decisão sem custo é sinal de que o trade-off não foi analisado.

## Alternativas rejeitadas

> Uma subseção `###` por alternativa, com o título sendo a alternativa e o corpo o motivo técnico da rejeição.
> **Não use tabela aqui:** linha de tabela é uma linha física, então o argumento inteiro teria de caber em uma linha de
> centenas de colunas — estoura o limite de 120 e torna ilegível o diff de qualquer ajuste.

### Opção A

Motivo técnico da rejeição, em prosa. Diga o que ela resolveria e por que o custo não compensa — "não gostamos" não é
motivo.

### Opção B

Idem.

## Quando revisitar

> Que fato novo tornaria esta decisão errada? Ex.: "se o time passar de 15 pessoas", "se o Dart passar a suportar X".

---

## Variante: decisão em aberto

Quando o problema e as opções candidatas já valem registro, mas a escolha ainda não foi feita, use o esqueleto abaixo
no lugar das seções `## Decisão` e `## Alternativas rejeitadas`. As demais seções do padrão (`## Contexto`) continuam
valendo.

```markdown
# ADR-NNN: Título curto no imperativo

- **Status:** Proposto — decisão em aberto
- **Data:** AAAA-MM-DD
- **Decisores:** Nome Completo (@handle)

> **Bloqueio:** enquanto este ADR estiver como Proposto, é proibido introduzir [o que a decisão vai regular] por
> iniciativa própria.

## Contexto

O problema e as restrições reais — igual à variante fechada.

## Restrições inegociáveis

<!-- Opcional. Condições que toda opção candidata DEVE satisfazer, independente de qual for escolhida. -->

- Restrição 1.

## Opção A — <nome>

### Estrutura

<!-- Opcional: árvore de diretórios, assinatura, diagrama. -->

### Uso

<!-- Opcional: código de exemplo. -->

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

| Critério | Opção A | Opção B |
| --- | --- | --- |
| Critério 1 | | |

## Recomendação para análise

<!-- Opcional: indicação de quem escreveu o ADR, sem forçar a decisão. -->

## Perguntas a responder antes de decidir

- O que falta saber para fechar a escolha?
```

### Ao fechar a decisão

1. `Status` muda para **Aceito**.
2. A opção escolhida vira `## Decisão`, em uma ou duas frases afirmativas.
3. As demais opções viram subseções `###` de `## Alternativas rejeitadas` — a `### Avaliação` de cada uma condensa
   no motivo técnico da rejeição.
4. `## Consequências` e `## Quando revisitar` passam a ser preenchidos.
5. A nota de bloqueio, `## Comparativo` e `## Perguntas a responder` são removidos.

O arquivo inteiro migra para o formato padrão deste template.
