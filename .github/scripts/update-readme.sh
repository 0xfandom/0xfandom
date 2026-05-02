#!/usr/bin/env bash
# Refreshes auto-managed README sections from live GitHub data.
#
# Sections (driven by sentinel markers):
#   <!-- START:featured -->        top 6 pinned public repos (GraphQL pinnedItems)
#   <!-- START:contributions -->   all upstream public PRs by $USER, any state
#
# Both sections always overwrite — empty placeholders show if there's no data,
# so the README stays in sync with reality.

set -euo pipefail

USER="0xfandom"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PRIORITY="Solidity Move Rust Go TypeScript Python Java Vyper Cairo Huff JavaScript C C++"
SKIP_LANGS="HTML CSS SCSS Shell Dockerfile Makefile Procfile MDX Nix HCL Roff Batchfile PowerShell Jupyter Notebook TeX"

# ---------------------------------------------------------------------------
# Stack resolver — runs the fallback chain for one pinned repo node.
#
# Order:
#   1. GraphQL languages.edges, filtered + priority-sorted, top 2
#   2. GraphQL primaryLanguage.name
#   3. Repo-name suffix heuristic (-rs → Rust, *MCP → TypeScript, etc.)
#   4. "—"
# ---------------------------------------------------------------------------
resolve_stack() {
  local node_json=$1
  local repo=$2

  local stack
  stack=$(echo "$node_json" | jq -r --arg priority "$PRIORITY" --arg skip "$SKIP_LANGS" '
    ($skip | split(" ")) as $skip_arr
    | ($priority | split(" ")) as $prio_arr
    | [.languages.edges[].node.name]
    | map(select(. as $k | $skip_arr | index($k) | not))
    | . as $langs
    | ([$prio_arr[] as $p | $langs[] | select(. == $p)] + $langs)
    | reduce .[] as $k ([]; if any(.[]; . == $k) then . else . + [$k] end)
    | .[0:2]
    | map("`\(.)`")
    | join(" ")
  ')
  if [ -n "$stack" ]; then
    echo "$stack"
    return
  fi

  local primary
  primary=$(echo "$node_json" | jq -r '.primaryLanguage.name // empty')
  if [ -n "$primary" ]; then
    echo "\`$primary\`"
    return
  fi

  local name="${repo##*/}"
  case "$name" in
    *-rs|*-Rust|Rust-*)             echo "\`Rust\`"; return ;;
    *-go|*-Go|Go-*)                 echo "\`Go\`"; return ;;
    *-ts|*-TS|TS-*)                 echo "\`TypeScript\`"; return ;;
    *-py|*-Python|Python-*)         echo "\`Python\`"; return ;;
    *-sol|*-Solidity|Solidity-*)    echo "\`Solidity\`"; return ;;
    *MCP*|*-mcp|*-MCP)              echo "\`TypeScript\`"; return ;;
    *Telegram*|*Discord*)           echo "\`TypeScript\`"; return ;;
  esac

  echo "—"
}

# ---------------------------------------------------------------------------
# Featured: top 6 pinned public repos via GraphQL pinnedItems.
# ---------------------------------------------------------------------------
PINNED_QUERY=$(cat <<EOF
{
  user(login: "$USER") {
    pinnedItems(first: 6, types: REPOSITORY) {
      totalCount
      nodes {
        ... on Repository {
          name
          nameWithOwner
          url
          description
          primaryLanguage { name }
          languages(first: 10, orderBy: {field: SIZE, direction: DESC}) {
            edges { size node { name } }
          }
        }
      }
    }
  }
}
EOF
)

gh api graphql -f query="$PINNED_QUERY" \
  | jq '.data.user.pinnedItems.nodes // []' > "$TMPDIR/pinned.json"

PINNED_COUNT=$(jq 'length' "$TMPDIR/pinned.json")

{
  if [ "$PINNED_COUNT" -gt 0 ]; then
    echo "| Project | Stack | What it does |"
    echo "| :--- | :--- | :--- |"
    jq -c '.[]' "$TMPDIR/pinned.json" | while read -r node; do
      repo=$(echo "$node" | jq -r '.nameWithOwner')
      name=$(echo "$node" | jq -r '.name')
      url=$(echo "$node" | jq -r '.url')
      desc=$(echo "$node" | jq -r '.description // "—"' | sed 's/|/\\|/g')
      stack=$(resolve_stack "$node" "$repo")
      echo "| **[$name]($url)** | $stack | $desc |"
    done
  else
    echo "_No pinned repos. Pin up to 6 on [your profile](https://github.com/$USER) to populate this section._"
  fi
} > "$TMPDIR/featured.md"

# ---------------------------------------------------------------------------
# Contributions: all upstream public PRs by $USER, any state, grouped by repo.
# `is:public` excludes private repos at search time so the README only
# advertises code reviewers can actually click through to.
# ---------------------------------------------------------------------------
gh search prs --author="$USER" --limit=1000 --json repository,title,url,state -- "-user:$USER" "is:public" \
  | jq --arg user "$USER" '
      [.[] | select(.repository.nameWithOwner | startswith($user + "/") | not)]
      | group_by(.repository.nameWithOwner)
      | map({
          repo: .[0].repository.nameWithOwner,
          count: length,
          prs: [.[] | {
            num: (.url | split("/") | .[-1] | tonumber),
            url: .url,
            title: .title,
            state: .state
          }] | sort_by(-.num)
        })
      | sort_by(-.count)' > "$TMPDIR/contributions.json"

: > "$TMPDIR/contributions.md"
jq -c '.[]' "$TMPDIR/contributions.json" | while read -r entry; do
  repo=$(echo "$entry" | jq -r '.repo')
  desc=$(gh api "repos/$repo" 2>/dev/null | jq -r '.description // "—"' | sed 's/|/\\|/g')
  display="${repo//\// / }"
  pr_url="https://github.com/$repo/pulls?q=author%3A$USER+is%3Apr"
  count=$(echo "$entry" | jq -r '.count')
  open_n=$(echo "$entry" | jq -r '[.prs[] | select(.state == "open")] | length')
  merged_n=$(echo "$entry" | jq -r '[.prs[] | select(.state == "merged")] | length')
  closed_n=$(echo "$entry" | jq -r '[.prs[] | select(.state == "closed")] | length')

  parts="$count PR$([ "$count" -gt 1 ] && echo s || true)"
  [ "$merged_n" -gt 0 ] && parts="$parts · 🟣 $merged_n"
  [ "$open_n"   -gt 0 ] && parts="$parts · 🟢 $open_n"
  [ "$closed_n" -gt 0 ] && parts="$parts · 🔴 $closed_n"

  {
    echo "<details>"
    echo "<summary><b>&nbsp;🛠️&nbsp; $display</b> &nbsp;·&nbsp; $desc &nbsp;·&nbsp; <sub>$parts &middot; <a href=\"$pr_url\">all PRs →</a></sub></summary>"
    echo
    echo "<br>"
    echo
    echo "$entry" | jq -r '
      .prs[]
      | "- " +
        (if   .state == "open"   then "🟢"
         elif .state == "merged" then "🟣"
         else                         "🔴" end)
        + " [`#\(.num)`](\(.url)) — \(.title | gsub("^\\s+|\\s+$"; ""))"
    '
    echo
    echo "</details>"
    echo
  } >> "$TMPDIR/contributions.md"
done

if [ ! -s "$TMPDIR/contributions.md" ]; then
  echo "_No external PRs found._" > "$TMPDIR/contributions.md"
fi

# ---------------------------------------------------------------------------
# Splice into README between <!-- START:NAME --> / <!-- END:NAME --> markers.
# Always splice — empty inputs render placeholders, never leave stale data.
# ---------------------------------------------------------------------------
python3 - "$README" "$TMPDIR" <<'PY'
import re, sys, pathlib
readme_path, tmpdir = sys.argv[1], sys.argv[2]
data = pathlib.Path(readme_path).read_text()

for marker in ("featured", "contributions"):
    content = pathlib.Path(f"{tmpdir}/{marker}.md").read_text().rstrip()
    pat = re.compile(rf"(<!-- START:{marker} -->).*?(<!-- END:{marker} -->)", re.DOTALL)
    data = pat.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", data)

pathlib.Path(readme_path).write_text(data)
print(f"README updated: {readme_path}")
PY
