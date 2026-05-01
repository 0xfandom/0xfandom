#!/usr/bin/env bash
# Refreshes the README's <!-- START:contributions --> section from live
# GitHub data — every public PR authored by $USER in any external repo,
# grouped by repo, in any state (open / merged / closed).
#
# Featured work is intentionally left manual — pin the projects you want
# highlighted by editing the README directly.

set -euo pipefail

USER="0xfandom"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ---------------------------------------------------------------------------
# Contributions: all upstream PRs by $USER, any state, grouped by repo.
# `-user:$USER` excludes own-account repos at search time so the result cap
# isn't burned on self-authored PRs.
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

# Build one closed <details> card per upstream repo.
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

  # State summary (e.g., "12 PRs · 🟣 8 · 🟢 3 · 🔴 1")
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
# Splice into README between <!-- START:contributions --> / <!-- END:contributions --> markers.
# ---------------------------------------------------------------------------
python3 - "$README" "$TMPDIR" <<'PY'
import re, sys, pathlib
readme_path, tmpdir = sys.argv[1], sys.argv[2]
data = pathlib.Path(readme_path).read_text()

content = pathlib.Path(f"{tmpdir}/contributions.md").read_text().rstrip()
pat = re.compile(r"(<!-- START:contributions -->).*?(<!-- END:contributions -->)", re.DOTALL)
data = pat.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", data)

pathlib.Path(readme_path).write_text(data)
print(f"README updated: {readme_path}")
PY
