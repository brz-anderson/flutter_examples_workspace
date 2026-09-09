#!/usr/bin/env bash
#
# Confere as regras de topologia do workspace que dão para verificar por ferramenta.
# Rode da raiz do workspace, antes de abrir pull request:
#
#   ./tool/check_topology.sh
#
# Sai com 0 se tudo passar, 1 se houver violação — mas roda todas as checagens antes de
# sair, para você ver o conjunto inteiro de uma vez.
#
# Regras cobertas, com a referência normativa:
#   1. Import contra a direção das camadas ....... docs/conventions/packages.md
#   2. Feature importando outra feature .......... docs/conventions/packages.md
#   3. Import contendo /src/ entre pacotes ....... docs/conventions/packages.md
#   4. Nome com _impl, com Datasource, ou com _ .. docs/conventions/dart-style.md
#
# A direção permitida é apps/ -> features/ -> design/ -> core/. O caminho inverso é
# proibido, e a checagem 1 é o que torna isso verificável para as duas fronteiras que o
# compilador não pega sozinho (core/ não declara o Flutter, então essa ele já garante).

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

FAILED=0
RED=$'\033[31m'
GREEN=$'\033[32m'
DIM=$'\033[2m'
OFF=$'\033[0m'

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Fontes Dart do projeto, sem build, .dart_tool e código gerado.
dart_sources() {
  git ls-files '*.dart' \
    | grep -v '/build/' \
    | grep -v '/\.dart_tool/' \
    | grep -v '/generated/'
}

report() {
  local titulo="$1" regra="$2" achados="$3"
  if [[ -z "$achados" ]]; then
    printf '%s  ok  %s%s %s(%s)%s\n' "$GREEN" "$OFF" "$titulo" "$DIM" "$regra" "$OFF"
  else
    printf '%s FALHA %s%s %s(%s)%s\n' "$RED" "$OFF" "$titulo" "$DIM" "$regra" "$OFF"
    printf '%s\n' "$achados" | sed 's/^/        /'
    FAILED=1
  fi
}

SOURCES="$(dart_sources)"
if [[ -z "$SOURCES" ]]; then
  echo "Nenhuma fonte Dart encontrada — rode da raiz do workspace." >&2
  exit 2
fi

# --- Mapa de pacotes: nome do pubspec -> camada e diretório ------------------------------
# O nome do pacote NÃO é o nome do diretório (prefixo example_), então o mapa é derivado
# do campo `name:` de cada pubspec.yaml — nada hard-coded.
#
# Formato de cada linha de $TMP/pacotes: <nome> <rank> <diretorio>
# Rank: core=1, design=2, features=3, apps=4. Import só é permitido de rank maior ou igual
# para rank menor; igual só quando não for feature.
: > "$TMP/pacotes"
for pubspec in $(git ls-files '*/pubspec.yaml'); do
  dir="${pubspec%/pubspec.yaml}"
  nome="$(sed -n 's/^name:[[:space:]]*\([A-Za-z0-9_]*\).*/\1/p' "$pubspec" | head -1)"
  [[ -z "$nome" ]] && continue
  case "$dir" in
    packages/core/*) rank=1 ;;
    packages/design/*) rank=2 ;;
    packages/features/*) rank=3 ;;
    apps/*) rank=4 ;;
    *) continue ;;
  esac
  printf '%s %s %s\n' "$nome" "$rank" "$dir" >> "$TMP/pacotes"
done

if [[ ! -s "$TMP/pacotes" ]]; then
  echo "Nenhum pacote do workspace encontrado sob apps/ ou packages/." >&2
  exit 2
fi

printf 'Pacotes do workspace: %s\n\n' "$(awk '{printf "%s ", $1}' "$TMP/pacotes")"

# Devolve "<rank> <nome>" do pacote a que um arquivo pertence, subindo os diretórios até
# achar o pubspec.yaml dono.
pacote_dono() {
  local caminho="$1" dir
  dir="$(dirname "$caminho")"
  while [[ "$dir" != "." && "$dir" != "/" ]]; do
    if [[ -f "$dir/pubspec.yaml" ]]; then
      awk -v d="$dir" '$3 == d { print $2, $1; exit }' "$TMP/pacotes"
      return
    fi
    dir="$(dirname "$dir")"
  done
}

# Devolve "<rank> <diretorio>" de um pacote pelo nome, ou vazio se não for do workspace.
pacote_por_nome() {
  awk -v n="$1" '$1 == n { print $2, $3; exit }' "$TMP/pacotes"
}

# --- 1 e 2. Direção das camadas, e feature importando feature ---------------------------
violacao_camada=''
violacao_feature=''
while IFS= read -r arquivo; do
  [[ -z "$arquivo" ]] && continue
  dono="$(pacote_dono "$arquivo")"
  [[ -z "$dono" ]] && continue
  rank_origem="${dono%% *}"
  nome_origem="${dono##* }"

  while IFS= read -r linha; do
    [[ -z "$linha" ]] && continue
    numero="${linha%%:*}"
    importado="$(printf '%s' "$linha" | sed -n "s#.*package:\([A-Za-z0-9_]*\)/.*#\1#p")"
    [[ -z "$importado" || "$importado" == "$nome_origem" ]] && continue
    alvo="$(pacote_por_nome "$importado")"
    [[ -z "$alvo" ]] && continue
    rank_alvo="${alvo%% *}"

    if (( rank_alvo > rank_origem )); then
      violacao_camada+="${arquivo}:${numero}: ${nome_origem} importa ${importado}"$'\n'
    elif (( rank_alvo == rank_origem )) && (( rank_origem == 3 )); then
      violacao_feature+="${arquivo}:${numero}: ${nome_origem} importa ${importado}"$'\n'
    fi
  done <<< "$(grep -nE "^import 'package:" "$arquivo" 2>/dev/null || true)"
done <<< "$SOURCES"

report 'Import contra a direção das camadas' 'apps -> features -> design -> core' \
  "$(printf '%s' "$violacao_camada" | sed '/^$/d')"
report 'Feature importando outra feature' 'uma vertical não depende de outra' \
  "$(printf '%s' "$violacao_feature" | sed '/^$/d')"

# --- 3. Import com /src/ entre pacotes --------------------------------------------------
# Um import `package:X/src/...` só é legítimo quando o arquivo pertence ao próprio X:
# `src/` é o privado do pacote, e a fachada pública é o barrel.
achados=''
while IFS= read -r arquivo; do
  [[ -z "$arquivo" ]] && continue
  dono="$(pacote_dono "$arquivo")"
  nome_origem="${dono##* }"
  hit="$(grep -nE "^import 'package:[A-Za-z0-9_]+/src/" "$arquivo" 2>/dev/null || true)"
  [[ -z "$hit" ]] && continue
  while IFS= read -r linha; do
    [[ -z "$linha" ]] && continue
    pacote="$(printf '%s' "$linha" | sed -n "s#.*package:\([A-Za-z0-9_]*\)/src/.*#\1#p")"
    [[ "$pacote" == "$nome_origem" ]] && continue
    achados+="${arquivo}:${linha}"$'\n'
  done <<< "$hit"
done <<< "$SOURCES"
report 'Import contendo /src/ a partir de outro pacote' 'src/ é privado do pacote' \
  "$(printf '%s' "$achados" | sed '/^$/d')"

# --- 4. Nomenclatura proibida em nome de arquivo ----------------------------------------
# Confere só o BASENAME: o diretório `data/datasources/` é a única ocorrência permitida do
# termo, então casar contra o caminho inteiro acusaria o que a convenção manda.
#
# O arquivo de implementação conserva o nome do contrato: o contrato em
# `domain/repositories/auth_repository.dart` e a implementação em
# `data/repositories/auth_repository.dart`, ambos com esse nome — só a CLASSE recebe o
# sufixo Impl. A camada já é dada pelo diretório, então repetir `_impl` no nome é
# redundância.
achados="$(printf '%s\n' "$SOURCES" | while IFS= read -r arquivo; do
  base="${arquivo##*/}"
  if [[ "$base" == *_impl.dart ]] \
    || [[ "$base" == *[Dd]ata[Ss]ource* ]] \
    || [[ "$base" == _* ]]; then
    printf '%s\n' "$arquivo"
  fi
done)"
report 'Arquivo com _impl, com Datasource no nome, ou com prefixo _' 'nome do contrato, sem _impl' "$achados"

achados="$(printf '%s\n' "$SOURCES" | tr '\n' '\0' \
  | xargs -0 grep -nE 'class [A-Za-z]*[Dd]ata[Ss]ource' 2>/dev/null || true)"
report 'Classe com Datasource no nome' 'a fonte de dado é um repositório' "$achados"

echo
if [[ "$FAILED" -eq 0 ]]; then
  printf '%sTopologia conforme.%s\n' "$GREEN" "$OFF"
else
  printf '%sTopologia com violação — ver acima.%s\n' "$RED" "$OFF"
fi
exit "$FAILED"
