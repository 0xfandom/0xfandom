#!/usr/bin/env bash
# Refreshes auto-managed README sections from live GitHub data.
#
# Sections (driven by sentinel markers):
#   <!-- START:featured -->        top 6 pinned public repos (GraphQL pinnedItems)
#   <!-- START:contributions -->   all upstream PRs by $USER, any state, grouped by repo
#
# Featured falls back to leaving content as-is when the user has 0 pinned
# repos — so an empty pin list never wipes the curated table.

set -euo pipefail

USER="0xfandom"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PRIORITY="Solidity Move Rust Go TypeScript Python Java Vyper Cairo Huff JavaScript C C++"
SKIP_LANGS="HTML CSS SCSS Shell Dockerfile Makefile Procfile MDX Nix HCL Roff Batchfile PowerShell"

# ---------------------------------------------------------------------------
# Featured: top 6 pinned public repos via GraphQL pinnedItems.
# Stack column resolved from /languages with priority + tooling filter.
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

if [ "$PINNED_COUNT" -gt 0 ]; then
  jq -r --arg priority "$PRIORITY" --arg skip "$SKIP_LANGS" '
    ($skip | split(" ")) as $skip_arr
    | ($priority | split(" ")) as $prio_arr
    | map({
        name,
        url,
        desc: ((.description // "—") | gsub("\\|"; "\\|")),
        stack: (
          [.languages.edges[].node.name]
          | map(select(. as $k | $skip_arr | index($k) | not))
          | . as $langs
          | ([$prio_arr[] as $p | $langs[] | select(. == $p)] + $langs)
          | reduce .[] as $k ([]; if any(.[]; . == $k) then . else . + [$k] end)
          | .[0:2]
          | map("`\(.)`")
          | join(" ")
        )
      })
    | .[]
    | "| **[\(.name)](\(.url))** | \(if .stack == "" then "—" else .stack end) | \(.desc) |"
  ' "$TMPDIR/pinned.json" > "$TMPDIR/featured_rows"

  {
    echo "| Project | Stack | What it does |"
    echo "| :--- | :--- | :--- |"
    cat "$TMPDIR/featured_rows"
  } > "$TMPDIR/featured.md"
else
  echo "No pinned repos — leaving featured section unchanged."
fi

# ---------------------------------------------------------------------------
# Contributions: all upstream PRs by $USER, any state, grouped by repo.
# ---------------------------------------------------------------------------
gh search prs --author="$USER" --limit=1000 --json repository,title,url,state -- "-user:$USER" \
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
# Splice into README. Skip a marker if its source file wasn't generated
# (so an empty pinned list doesn't wipe curated content).
# ---------------------------------------------------------------------------
python3 - "$README" "$TMPDIR" <<'PY'
import re, sys, pathlib
readme_path, tmpdir = sys.argv[1], sys.argv[2]
data = pathlib.Path(readme_path).read_text()

for marker in ("featured", "contributions"):
    fp = pathlib.Path(f"{tmpdir}/{marker}.md")
    if not fp.exists():
        continue
    content = fp.read_text().rstrip()
    pat = re.compile(rf"(<!-- START:{marker} -->).*?(<!-- END:{marker} -->)", re.DOTALL)
    data = pat.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", data)

pathlib.Path(readme_path).write_text(data)
print(f"README updated: {readme_path}")
PY
