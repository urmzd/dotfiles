#!/usr/bin/env bash
# trending: one read-only digest of what is trending, from public endpoints.
# No account, no token, no cookies. Needs curl and jq.
set -uo pipefail

usage() {
    cat <<'EOF'
Usage: trending.sh [--limit N] [--since daily|weekly|monthly] [--lang LANG]
                   [--sources LIST] [--help]

Print what is trending right now as tab-separated sections. Every source is
public: nothing is sent but the query itself.

Options:
  --limit N        Rows per section. Default 20. Sources cap lower:
                   GitHub trending serves up to 25, Lobsters 25.
  --since WINDOW   daily (default), weekly, or monthly. GITHUB NEW never
                   looks back less than 7 days.
  --lang LANG      GitHub language filter, e.g. rust, go, typescript.
                   Hacker News and Lobsters ignore it.
  --sources LIST   Comma-separated subset of:
                   github-trending,github-new,hn,lobsters   (default: all)
  --help           Show this text.

Sections (stdout, TSV with a header row):
  ## GITHUB TRENDING   rank  repo  gained  stars  language  description  url
  ## GITHUB NEW        rank  repo  stars  created  language  description  url
  ## HACKER NEWS       rank  points  comments  title  url  discussion
  ## LOBSTERS          rank  score  comments  tags  title  url  discussion

A source that fails prints "unavailable: <reason>" under its heading and a
note on stderr; the rest still print. Exit 0 when at least one source
answered, 1 when none did, 2 on a usage error.

Examples:
  trending.sh
  trending.sh --since weekly --lang rust --limit 10
  trending.sh --sources hn,lobsters
EOF
}

limit=20
since=daily
lang=""
sources="github-trending,github-new,hn,lobsters"

while [ $# -gt 0 ]; do
    case "$1" in
        --limit) limit="${2:-}"; shift 2 || { usage >&2; exit 2; } ;;
        --since) since="${2:-}"; shift 2 || { usage >&2; exit 2; } ;;
        --lang) lang="${2:-}"; shift 2 || { usage >&2; exit 2; } ;;
        --sources) sources="${2:-}"; shift 2 || { usage >&2; exit 2; } ;;
        -h | --help) usage; exit 0 ;;
        *) echo "trending.sh: unknown argument: $1 (try --help)" >&2; exit 2 ;;
    esac
done

case "$limit" in
    '' | *[!0-9]* | 0) echo "trending.sh: --limit needs a positive number, got '$limit'" >&2; exit 2 ;;
esac
case "$since" in
    daily) days=1 ;;
    weekly) days=7 ;;
    monthly) days=30 ;;
    *) echo "trending.sh: --since must be daily, weekly or monthly, got '$since'" >&2; exit 2 ;;
esac

old_ifs=$IFS
IFS=,
for s in $sources; do
    case "$s" in
        github-trending | github-new | hn | lobsters) ;;
        *) IFS=$old_ifs; echo "trending.sh: unknown source '$s' (valid: github-trending,github-new,hn,lobsters)" >&2; exit 2 ;;
    esac
done
IFS=$old_ifs
[ -n "$sources" ] || { echo "trending.sh: --sources is empty" >&2; exit 2; }

for tool in curl jq; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "trending.sh: $tool is required but not installed" >&2
        exit 1
    }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

ok=0
want() { case ",$sources," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }
uri() { jq -rn --arg v "$1" '$v|@uri'; }

# fetch <url> <outfile>: 0 on HTTP 200, otherwise sets $reason.
reason=""
fetch() {
    local code
    code=$(curl -sS -L -m 20 -A "trending-digest/1.0" -H "Accept: ${3:-*/*}" \
        -o "$2" -w '%{http_code}' "$1" 2>"$work/err") || {
        reason=$(head -1 "$work/err")
        return 1
    }
    [ "$code" = 200 ] && return 0
    reason="HTTP $code"
    case "$code" in 403 | 429) reason="$reason (rate limited, retry in a minute)" ;; esac
    return 1
}

unavailable() { # <source> <reason>
    printf 'unavailable: %s\n' "$2"
    echo "trending.sh: $1 unavailable: $2" >&2
}

# GNU date takes -d, BSD date takes -v.
days_ago() { date -u -v-"$1"d "+$2" 2>/dev/null || date -u -d "$1 days ago" "+$2"; }

# jq filter shared by the JSON sources: flatten whitespace, cap length.
clean='def clean: (. // "") | tostring | gsub("[\\t\\n\\r]+"; " ") | if length > 140 then .[0:137] + "..." elif . == "" then "-" else . end;'

if want github-trending; then
    echo "## GITHUB TRENDING ($since${lang:+, $lang})"
    path=""
    [ -n "$lang" ] && path="/$(uri "$(printf '%s' "$lang" | tr '[:upper:] ' '[:lower:]-')")"
    if fetch "https://github.com/trending$path?since=$since" "$work/trending.html"; then
        rows=$(awk -v limit="$limit" '
            function trim(s) { gsub(/^[ \t\r]+|[ \t\r]+$/, "", s); return s }
            function decode(s) {
                gsub(/&amp;/, "\\&", s); gsub(/&lt;/, "<", s); gsub(/&gt;/, ">", s)
                gsub(/&quot;/, "\"", s); gsub(/&#39;/, "\047", s); gsub(/\t/, " ", s)
                return s
            }
            function flush() {
                if (repo == "" || n >= limit) return
                n++
                if (length(desc) > 140) desc = substr(desc, 1, 137) "..."
                printf "%d\t%s\t%s\t%s\t%s\t%s\thttps://github.com/%s\n", n, repo, \
                    (gained == "" ? "-" : gained), (stars == "" ? "-" : stars), \
                    (language == "" ? "-" : language), decode(desc), repo
            }
            /<article class="Box-row"/ { flush(); repo = desc = language = stars = gained = ""; want_desc = want_stars = 0 }
            /<p class="col-9/ { want_desc = 1; next }
            want_desc { desc = $0; gsub(/<[^>]*>/, "", desc); desc = trim(desc); want_desc = 0; next }
            /itemprop="programmingLanguage"/ {
                language = $0
                sub(/.*itemprop="programmingLanguage">/, "", language); sub(/<.*/, "", language)
            }
            /href="\/[^\/"]+\/[^\/"]+\/stargazers"/ {
                repo = $0
                sub(/.*href="\//, "", repo); sub(/\/stargazers".*/, "", repo)
                want_stars = 1
            }
            want_stars && /^[ \t]*[0-9][0-9,]*<\/a>/ { stars = trim($0); sub(/<.*/, "", stars); gsub(/,/, "", stars); want_stars = 0 }
            /[0-9] stars? (today|this week|this month)/ { gained = trim($0); sub(/ .*/, "", gained); gsub(/,/, "", gained) }
            END { flush() }
        ' "$work/trending.html")
        if [ -n "$rows" ]; then
            printf 'rank\trepo\tgained\tstars\tlanguage\tdescription\turl\n%s\n' "$rows"
            ok=1
        else
            unavailable github-trending "page layout changed, no repositories parsed"
        fi
    else
        unavailable github-trending "$reason"
    fi
    echo
fi

if want github-new; then
    # A repo needs a few days to gather stars: a one-day window returns
    # mostly star-farmed spam, so the window never drops below a week.
    new_days=$days
    [ "$new_days" -lt 7 ] && new_days=7
    cutoff=$(days_ago "$new_days" %Y-%m-%d)
    echo "## GITHUB NEW (created after $cutoff${lang:+, $lang})"
    q="created:>$cutoff"
    [ -n "$lang" ] && q="$q language:$lang"
    per=$limit
    [ "$per" -gt 100 ] && per=100
    if fetch "https://api.github.com/search/repositories?q=$(uri "$q")&sort=stars&order=desc&per_page=$per" \
        "$work/new.json" "application/vnd.github+json"; then
        printf 'rank\trepo\tstars\tcreated\tlanguage\tdescription\turl\n'
        jq -r "$clean"'
            .items | to_entries[] | [.key + 1, .value.full_name, .value.stargazers_count,
                .value.created_at[0:10], (.value.language // "-"),
                (.value.description | clean), .value.html_url] | @tsv' "$work/new.json"
        ok=1
    else
        unavailable github-new "$reason"
    fi
    echo
fi

if want hn; then
    echo "## HACKER NEWS ($since)"
    per=$limit
    [ "$per" -gt 100 ] && per=100
    if [ "$since" = daily ]; then
        hn_url="https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=$per"
    else
        hn_url="https://hn.algolia.com/api/v1/search?tags=story&numericFilters=$(uri "created_at_i>$(($(date +%s) - days * 86400))")&hitsPerPage=$per"
    fi
    if fetch "$hn_url" "$work/hn.json"; then
        printf 'rank\tpoints\tcomments\ttitle\turl\tdiscussion\n'
        jq -r "$clean"'
            .hits | sort_by(-(.points // 0)) | to_entries[] |
            ("https://news.ycombinator.com/item?id=" + .value.objectID) as $d |
            [.key + 1, (.value.points // 0), (.value.num_comments // 0),
                (.value.title | clean), (.value.url // $d), $d] | @tsv' "$work/hn.json"
        ok=1
    else
        unavailable hn "$reason"
    fi
    echo
fi

if want lobsters; then
    echo "## LOBSTERS (hottest)"
    if fetch "https://lobste.rs/hottest.json" "$work/lobsters.json"; then
        printf 'rank\tscore\tcomments\ttags\ttitle\turl\tdiscussion\n'
        jq -r --argjson limit "$limit" "$clean"'
            .[0:$limit] | to_entries[] |
            [.key + 1, .value.score, .value.comment_count, (.value.tags | join(",")),
                (.value.title | clean),
                (if (.value.url // "") == "" then .value.short_id_url else .value.url end),
                .value.short_id_url] | @tsv' "$work/lobsters.json"
        ok=1
    else
        unavailable lobsters "$reason"
    fi
    echo
fi

if [ "$ok" = 0 ]; then
    echo "trending.sh: no source answered (sources: $sources)" >&2
    exit 1
fi
