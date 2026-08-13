#!/usr/bin/env bash
# Health check for stefanoscibilia.com. Run it any time:  ./check-site.sh
# Checks DNS, the TLS certificate, every page, and every outbound link.

set -uo pipefail
DOMAIN="stefanoscibilia.com"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0 Safari/537.36"
PAGES=("" "research.html" "teaching.html" "outreach.html" "contacts.html")
fail=0

echo "── DNS ──────────────────────────────────────────────"
ips=$(dig +short "$DOMAIN" A @1.1.1.1)
if [ -z "$ips" ]; then
  echo "  ✗ no A records — the domain does not resolve"; fail=1
else
  while read -r ip; do
    case "$ip" in
      185.199.10[89].153|185.199.11[01].153) echo "  ✓ $ip  GitHub Pages (unproxied)" ;;
      104.*|172.6[4-9].*|172.7[01].*)        echo "  ! $ip  Cloudflare proxy is ON (orange cloud)" ;;
      *)                                     echo "  ? $ip  unexpected address"; fail=1 ;;
    esac
  done <<< "$ips"
fi

echo
echo "── TLS certificate ──────────────────────────────────"
end=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
      | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -z "$end" ]; then
  echo "  ✗ could not read a certificate"; fail=1
else
  end_s=$(date -j -f "%b %e %T %Y %Z" "$end" +%s 2>/dev/null)
  days=$(( (end_s - $(date +%s)) / 86400 ))
  issuer=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
           | openssl x509 -noout -issuer 2>/dev/null | sed 's/.*CN=//')
  if [ "$days" -lt 14 ]; then
    echo "  ✗ expires in $days days ($end) — GitHub should have renewed by now"; fail=1
  else
    echo "  ✓ valid $days more days (until $end, issuer $issuer)"
  fi
fi

echo
echo "── Pages ────────────────────────────────────────────"
for p in "${PAGES[@]}"; do
  code=$(curl -sS -o /dev/null -A "$UA" --max-time 20 -w "%{http_code}" "https://$DOMAIN/$p" 2>/dev/null)
  if [ "$code" = "200" ]; then printf "  ✓ %-16s %s\n" "/$p" "$code"
  else printf "  ✗ %-16s %s\n" "/$p" "$code"; fail=1; fi
done
code=$(curl -sS -o /dev/null -A "$UA" --max-time 20 -w "%{http_code}" "https://$DOMAIN/no-such-page" 2>/dev/null)
[ "$code" = "404" ] && echo "  ✓ unknown URL returns 404" || { echo "  ✗ unknown URL returned $code, expected 404"; fail=1; }

echo
echo "── Outbound links ───────────────────────────────────"
links=$(for p in "${PAGES[@]}"; do curl -sS -A "$UA" --max-time 20 "https://$DOMAIN/$p" 2>/dev/null; done \
        | grep -o 'href="https\?://[^"]*"' | sed 's/href="//;s/"$//' \
        | grep -v "$DOMAIN" | sort -u)
while read -r u; do
  [ -z "$u" ] && continue
  code=$(curl -sS -o /dev/null -L -A "$UA" --max-time 25 -w "%{http_code}" "$u" 2>/dev/null)
  case "$code" in
    2*)   printf "  ✓ %s\n" "$u" ;;
    999)  printf "  ~ %s (LinkedIn blocks bots; fine in a browser)\n" "$u" ;;
    *)    printf "  ✗ %s  [%s]\n" "$u" "$code"; fail=1 ;;
  esac
done <<< "$links"

echo
[ "$fail" -eq 0 ] && echo "All good." || echo "Some checks failed — see the ✗ lines above."
exit $fail
