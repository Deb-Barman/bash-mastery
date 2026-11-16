#!/usr/bin/env bash
# ==========================================================
# Lesson 19 - Code.sh
# Topic : regular expressions with grep -E, sed -E, awk, and
#         Bash's [[ =~ ]] with BASH_REMATCH
# Run   : bash Code.sh
# Safe  : works ONLY inside ~/bash-practice/lesson19-demo
#         and cleans up after itself.
# ==========================================================

DEMO="$HOME/bash-practice/lesson19-demo"

if [ -d "$DEMO" ]; then
    rm -r "$DEMO"
fi
mkdir -p "$DEMO"
cd "$DEMO" || exit 1

# --- SAMPLE DATA -------------------------------------------
cat > app.log << 'EOF'
2026-10-10 09:00:01 [INFO] server started on 10.0.0.5
2026-10-10 09:02:44 [ERROR] database timeout from 192.168.1.20
2026-10-10 09:03:00 [INFO] retry from 192.168.1.20
2026-10-10 09:05:30 [WARN] disk 85 percent full
2026-10-10 09:07:12 [ERROR] failed to send email to asha@example.com
2026-10-10 09:09:41 [INFO] user ravi logged in from 10.0.0.9
2026-10-10 09:10:15 [ERROR] payment declined for card 4111 2222 3333 4444
EOF

cat > config.conf << 'EOF'
# Server settings
port = 8080

   # indented comment
host = localhost

debug = false
EOF

printf 'the quick brown fox\nthe the end\nno repeats here\nit was was a mistake\n' > essay.txt

# --- PART 1: grep -E basics --------------------------------
echo "== Part 1: grep -E =="
echo "-- lines containing ERROR or WARN (alternation) --"
grep -E 'ERROR|WARN' app.log | cut -c1-60
echo "-- count of ERROR lines --"
grep -E -c 'ERROR' app.log
echo "-- lines that START with a date and END with a digit --"
grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}.*[0-9]$' app.log | cut -c1-60
echo "-- -o prints ONLY the matching part: every IP address --"
grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' app.log
echo "-- which IPs appear most? --"
grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' app.log | sort | uniq -c | sort -rn
echo "-- log levels --"
grep -E -o '\[(INFO|WARN|ERROR)\]' app.log | sort | uniq -c
echo ""

# --- PART 2: classes, quantifiers, anchors -----------------
echo "== Part 2: a tiny regex tester =="
check() {                       # check REGEX TEXT...
    local re="$1" s
    shift
    printf 'regex: %s\n' "$re"
    for s in "$@"; do
        if [[ $s =~ $re ]]; then
            printf '   match     : [%s]\n' "$s"
        else
            printf '   no match  : [%s]\n' "$s"
        fi
    done
}
check '^[0-9]+$'                  123 12a "" -5
check '^-?[0-9]+(\.[0-9]+)?$'     3.14 -2 7. abc
check '^colou?r$'                 color colour colouur
check '^[A-Z][a-z]{2,}$'          Asha A Ravi ravi
check '^[6-9][0-9]{9}$'           9876543210 1234567890 98765
check '^#[0-9A-Fa-f]{6}$'         '#1A2b3C' '#12345' '#GGGGGG'
echo ""
echo "-- anchors matter: without ^ and $ the pattern matches INSIDE a longer text --"
check '[0-9]+'                    abc123def
check '^[0-9]+$'                  abc123def
echo ""

# --- PART 3: validation patterns ---------------------------
echo "== Part 3: validation patterns =="
echo "-- dates (shape only) --"
check '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'  2026-10-11 26-10-11 2026-1-1
echo "-- times --"
check '^([01][0-9]|2[0-3]):[0-5][0-9]$'  09:30 23:59 24:00 9:30
echo "-- email (simple) --"
re_email='^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
check "$re_email" asha@example.com bad@ @nouser.com a.b+c@mail.co.in
echo "-- IPv4 shape (note: 999.1.1.1 passes the SHAPE test) --"
check '^([0-9]{1,3}\.){3}[0-9]{1,3}$'  192.168.1.1 999.1.1.1 1.2.3 1.2.3.4.5
echo ""

# --- PART 4: capture groups with BASH_REMATCH --------------
echo "== Part 4: capture groups (BASH_REMATCH) =="
date_text="2026-10-11"
if [[ $date_text =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "whole match : ${BASH_REMATCH[0]}"
    echo "year        : ${BASH_REMATCH[1]}"
    echo "month       : ${BASH_REMATCH[2]}"
    echo "day         : ${BASH_REMATCH[3]}"
    echo "as DD/MM/YYYY: ${BASH_REMATCH[3]}/${BASH_REMATCH[2]}/${BASH_REMATCH[1]}"
fi
line='2026-10-10 09:02:44 [ERROR] database timeout from 192.168.1.20'
if [[ $line =~ \[([A-Z]+)\]\ (.*)\ from\ ([0-9.]+)$ ]]; then
    echo "level   = ${BASH_REMATCH[1]}"
    echo "message = ${BASH_REMATCH[2]}"
    echo "source  = ${BASH_REMATCH[3]}"
fi
echo ""

# --- PART 5: sed -E ----------------------------------------
echo "== Part 5: sed -E =="
echo "-- mask every digit in the card number --"
grep 'card' app.log | sed -E 's/[0-9]/X/g' | cut -c21-
echo "-- swap date format 2026-10-10 -> 10/10/2026 (using groups) --"
head -n 2 app.log | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})/\3\/\2\/\1/' | cut -c1-40
echo "-- wrap every number in <> using & (the whole match) --"
echo "I have 3 cats and 12 dogs" | sed -E 's/[0-9]+/<&>/g'
echo "-- reorder an email: user@domain -> domain (user) --"
echo "asha@example.com" | sed -E 's/^([^@]+)@(.+)$/\2 (\1)/'
echo "-- greedy vs not: remove HTML tags --"
html='<b>bold</b> and <i>italic</i>'
echo "greedy  .*    : $(echo "$html" | sed -E 's/<.*>//')"
echo "careful [^>]* : $(echo "$html" | sed -E 's/<[^>]*>//g')"
echo ""

# --- PART 6: cleaning files --------------------------------
echo "== Part 6: strip comments and blank lines =="
echo "Original config.conf has $(wc -l < config.conf) lines. Cleaned:"
grep -E -v '^[[:space:]]*(#|$)' config.conf
echo ""

# --- PART 7: repeated words (back-reference) ---------------
echo "== Part 7: back-references: repeated words =="
grep -E -n '\b([A-Za-z]+) \1\b' essay.txt
echo ""

# --- PART 8: awk with regex --------------------------------
echo "== Part 8: awk =="
echo "-- lines where the 3rd field matches [ERROR] --"
awk '$3 ~ /ERROR/ {print $1, $2, $3}' app.log
echo "-- count of lines per level using a regex match --"
awk '/\[INFO\]/ {i++} /\[WARN\]/ {w++} /\[ERROR\]/ {e++} END {print "INFO="i, "WARN="w, "ERROR="e}' app.log
echo ""

# --- PART 9: grep -P (PCRE) if available -------------------
echo "== Part 9: grep -P (PCRE: GNU only) =="
if echo test | grep -P 't' > /dev/null 2>&1; then
    echo "-- numbers followed by the word 'percent' (lookahead) --"
    grep -P -o '\d+(?= percent)' app.log
    echo "-- lazy quantifier .*? : first quoted word --"
    echo 'say "hello" and "bye"' | grep -P -o '"[^"]*?"' | head -n 1
else
    echo "(grep -P is not available here, for example on macOS; ERE covers most needs)"
fi
echo ""

# --- PART 10: rename files with a regex --------------------
echo "== Part 10: rename with regex captures =="
touch photo_2026-10-11.jpg photo_2026-10-12.jpg notes.txt
echo "Before: $(printf '[%s] ' *.jpg *.txt)"
for f in photo_*.jpg; do
    if [[ $f =~ ^photo_([0-9]{4})-([0-9]{2})-([0-9]{2})\.jpg$ ]]; then
        mv -- "$f" "${BASH_REMATCH[1]}_${BASH_REMATCH[2]}_${BASH_REMATCH[3]}.jpg"
    fi
done
echo "After : $(printf '[%s] ' *.jpg *.txt)"
echo ""

# --- CLEANUP -----------------------------------------------
cd "$HOME" || exit 1
rm -r "$DEMO"
echo "Cleaned up. Demo folder removed. Run me again anytime!"
