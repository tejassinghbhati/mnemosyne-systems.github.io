#!/bin/sh
#
# generate.sh — build the billetsys documentation site with pandoc.
#
# It pulls the Markdown manual (and its images) straight from the billetsys
# repository and renders one HTML page per chapter using template.html and
# doc.css. Re-run it whenever the upstream manual changes.
#
# Requirements: pandoc, gh (authenticated against github.com), base64.
#
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$HERE"

REPO="mnemosyne-systems/billetsys"
BRANCH="main"
MANUAL="doc/manual/en"

command -v pandoc >/dev/null 2>&1 || { echo "error: pandoc is required" >&2; exit 1; }
command -v gh     >/dev/null 2>&1 || { echo "error: gh is required"     >&2; exit 1; }

SRC=$(mktemp -d)
trap 'rm -rf "$SRC"' EXIT

# Page table: <output-slug>|<source-basename>|<Title>
# The order also drives the prev/next footer links.
PAGES="
introduction|01-introduction|Introduction
getting-started|02-gettingstarted|Getting Started
navigation|24-navigation|Navigation
roles|03-roles|Roles
user|04-user|User
superuser|05-superuser|Superuser
tam|06-tam|TAM
support|07-support|Support
admin|08-admin|Admin
tickets|11-tickets|Tickets
messages|12-messages|Messages
attachments|13-attachments|Attachments
email|14-email|Email
import|60-import|Ticket Import
articles|09-articles|Articles
reports|10-reports|Reports
pdf|23-pdf|PDF Export
companies|15-companies|Companies
users|16-users|Users
categories|17-categories|Categories
entitlements|18-entitlements|Entitlements
levels|19-levels|Levels
versions|20-versions|Versions
profile|21-profile|Profile
security|22-security|Security
password-reset|25-password-reset|Password Reset
architecture|72-architecture|Architecture
building|73-building|Building
"

fetch() { # <repo-path> <dest>
  gh api "repos/$REPO/contents/$1?ref=$BRANCH" --jq '.content' | base64 -d > "$2"
}

# Render one chapter. Conditionally appended args keep titles with spaces intact.
render() { # <slug> <src> <title> <prevhref> <prevtitle> <nexthref> <nexttitle>
  slug=$1; title=$3; ph=$4; pt=$5; nh=$6; nt=$7
  set -- "$SRC/$slug.md" \
    --from=markdown+raw_tex-yaml_metadata_block --to=html5 --standalone \
    --template=template.html --toc --toc-depth=3 \
    --metadata "title=$title" --metadata lang=en -V "nav_$slug=true"
  [ -n "$ph" ] && set -- "$@" -V "prevhref=$ph" -V "prevtitle=$pt"
  [ -n "$nh" ] && set -- "$@" -V "nexthref=$nh" -V "nexttitle=$nt"
  pandoc "$@" --output="$slug.html"
}

# Normalise the table into a clean newline-delimited list.
LIST=$(printf '%s\n' "$PAGES" | sed '/^[[:space:]]*$/d')
COUNT=$(printf '%s\n' "$LIST" | wc -l | tr -d ' ')

echo "Fetching manual from $REPO@$BRANCH ..."
printf '%s\n' "$LIST" | while IFS='|' read -r slug src title; do
  fetch "$MANUAL/$src.md" "$SRC/$slug.md"
done

# Fetch every image referenced by the manual.
mkdir -p images
imgs=$(grep -roh 'images/[A-Za-z0-9._-]\+' "$SRC" | sort -u || true)
for ref in $imgs; do
  name=${ref#images/}
  [ -f "images/$name" ] || fetch "$MANUAL/$ref" "images/$name" || \
    echo "  warn: missing image $name" >&2
done

echo "Rendering $COUNT pages with pandoc ..."
n=0
while IFS='|' read -r slug src title; do
  n=$((n + 1))
  prevhref=""; prevtitle=""; nexthref=""; nexttitle=""
  if [ "$n" -gt 1 ]; then
    prevline=$(printf '%s\n' "$LIST" | sed -n "$((n - 1))p")
    prevhref="$(printf '%s' "$prevline" | cut -d'|' -f1).html"
    prevtitle=$(printf '%s' "$prevline" | cut -d'|' -f3)
  fi
  if [ "$n" -lt "$COUNT" ]; then
    nextline=$(printf '%s\n' "$LIST" | sed -n "$((n + 1))p")
    nexthref="$(printf '%s' "$nextline" | cut -d'|' -f1).html"
    nexttitle=$(printf '%s' "$nextline" | cut -d'|' -f3)
  fi
  render "$slug" "$src" "$title" "$prevhref" "$prevtitle" "$nexthref" "$nexttitle"
  echo "  $slug.html"
done <<EOF
$LIST
EOF

echo "Done. $COUNT pages written to $HERE"
