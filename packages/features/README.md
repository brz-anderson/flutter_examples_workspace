# packages/features/

Uma vertical de funcionalidade por pacote. Cada um é um recorte completo — domínio, dados e apresentação da sua
própria funcionalidade — e é substituível sem tocar nos outros.

## O que entra

Um pacote de feature costuma organizar-se assim:

```
lib/
  domain/        entidades, contratos de repositório, casos de uso
  data/          implementação dos repositórios, fontes de dados
  presentation/  páginas, widgets e estado da funcionalidade
```

## O que não entra

- Widget genérico que outra feature vá querer: promova para `design/`.
- Tipo ou contrato compartilhado entre features: promova para `core/`.
- Composition root e registro de dependências: isso é do app que consome a feature.

## Dependências

`design/` e `core/`. **Uma feature não depende de outra feature** — se duas precisam da mesma coisa, essa coisa
pertence a uma camada mais interna.

## Exposição

Exporte um barril único (`lib/example_<feature>.dart`) com o que o app precisa montar. O resto fica em `lib/src/`,
fora do alcance de quem consome.
