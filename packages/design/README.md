# packages/design/

Apresentação reutilizável: widgets, tema, tokens. **Sem regra de negócio.**

## O que entra

- Design system: tokens de cor, tipografia, espaçamento.
- Widgets genéricos — botões, campos, estados de carregamento e erro.
- Extensões de tema e helpers de layout.

## O que não entra

- Regra de negócio, chamada de repositório, gerenciamento de estado de funcionalidade. Isso é `features/`.
- Texto de domínio fixo no widget. O widget recebe o que exibir; quem sabe o que exibir é quem o usa.

## Dependências

Flutter e `core/`. Nunca `features/` nem `apps/`.

## Critério prático

Se o widget só faz sentido dentro de uma funcionalidade específica, ele não é desta camada — é de `features/`. O teste
é conseguir renderizá-lo numa galeria, isolado, sem montar nada de domínio.
