#!/bin/zsh
# Send one plain-text email using the settings in job-hunter.config.json.
# Usage: printf 'body\n' | send-email.sh "Subject"
#        send-email.sh --check
#
# Supported backends:
#   mailapp - send through the account already configured in macOS Mail
#   smtp    - send through an SMTP server (curl)
set -u
setopt NULL_GLOB

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"

if [ ! -r "$CONFIG" ]; then
  print -u2 -- "config not found: $CONFIG"
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  print -u2 -- "jq is required"
  exit 2
fi

field() {
  jq -r "$1" "$CONFIG"
}

enabled="$(field '.notifications.email.enabled // false')"
if [ "$enabled" != "true" ]; then
  print -u2 -- "email notifications are disabled in $CONFIG"
  exit 3
fi

BACKEND="$(field '.notifications.email.backend // "smtp"')"
MAIL_TO_JSON="$(field '.notifications.email.to // []')"
if [ "$(print -r -- "$MAIL_TO_JSON" | jq -r 'type')" != "array" ]; then
  print -u2 -- "notifications.email.to must be an array"
  exit 2
fi

MAIL_TO_JOINED="$(print -r -- "$MAIL_TO_JSON" | jq -r 'join(", ")')"
MAIL_TO_LINES="$(print -r -- "$MAIL_TO_JSON" | jq -r '.[]')"
MAIL_FROM="$(field '.notifications.email.from // empty')"

if [ -z "$MAIL_TO_JOINED" ]; then
  print -u2 -- "notifications.email.to is empty"
  exit 2
fi

case "$BACKEND" in
  mailapp)
    command -v osascript >/dev/null 2>&1 || { print -u2 -- "osascript is required"; exit 2; }
    if [ "${1:-}" = "--check" ]; then
      print -r -- "email config OK: Mail.app -> $MAIL_TO_JOINED"
      exit 0
    fi
    ;;
  smtp)
    SMTP_HOST="$(field '.notifications.email.smtp.host // empty')"
    SMTP_PORT="$(field '.notifications.email.smtp.port // 465')"
    SMTP_SECURITY="$(field '.notifications.email.smtp.security // "ssl"')"
    SMTP_USER="$(field '.notifications.email.smtp.user // empty')"
    SMTP_PASS="$(field '.notifications.email.smtp.password // empty')"
    MAIL_FROM="${MAIL_FROM:-$SMTP_USER}"

    missing=()
    [ -n "$MAIL_FROM" ] || missing+=(MAIL_FROM)
    [ -n "$SMTP_HOST" ] || missing+=(SMTP_HOST)
    [ -n "$SMTP_USER" ] || missing+=(SMTP_USER)
    [ -n "$SMTP_PASS" ] || missing+=(SMTP_PASS)
    if [ ${#missing[@]} -gt 0 ]; then
      print -u2 -- "missing email settings: ${(j:, :)missing}"
      exit 2
    fi

    if [ "${1:-}" = "--check" ]; then
      print -r -- "email config OK: SMTP $SMTP_USER -> $MAIL_TO_JOINED via $SMTP_HOST:$SMTP_PORT ($SMTP_SECURITY)"
      exit 0
    fi
    ;;
  *)
    print -u2 -- "unknown notifications.email.backend: $BACKEND (use mailapp or smtp)"
    exit 2
    ;;
esac

subject="${1:-Job Hunter notification}"
body_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-mail.XXXXXX")"
message_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-msg.XXXXXX")"
trap 'rm -f "$body_file" "$message_file"' EXIT

cat > "$body_file"

if [ "$BACKEND" = "mailapp" ]; then
  osascript - "$MAIL_TO_LINES" "$subject" "$body_file" "$MAIL_FROM" <<'APPLESCRIPT'
on run argv
  set toLines to item 1 of argv
  set theSubject to item 2 of argv
  set bodyPath to item 3 of argv
  set fromAddr to item 4 of argv
  set theBody to (read POSIX file bodyPath as «class utf8»)
  tell application "Mail"
    set props to {subject:theSubject, content:theBody, visible:false}
    if fromAddr is not "" then set props to props & {sender:fromAddr}
    set newMessage to make new outgoing message with properties props
    tell newMessage
      repeat with addr in paragraphs of toLines
        if contents of addr is not "" then
          make new to recipient at end of to recipients with properties {address:(contents of addr)}
        end if
      end repeat
      send
    end tell
  end tell
end run
APPLESCRIPT
  exit $?
fi

{
  print -r -- "To: $MAIL_TO_JOINED"
  print -r -- "From: $MAIL_FROM"
  print -r -- "Subject: $subject"
  print -r -- "MIME-Version: 1.0"
  print -r -- "Content-Type: text/plain; charset=UTF-8"
  print -r -- "Content-Transfer-Encoding: base64"
  print -r -- ""
  base64 < "$body_file"
} > "$message_file"

case "$SMTP_SECURITY" in
  ssl)      url="smtps://$SMTP_HOST:$SMTP_PORT"; tls=() ;;
  starttls) url="smtp://$SMTP_HOST:$SMTP_PORT";  tls=(--ssl-reqd) ;;
  none)     url="smtp://$SMTP_HOST:$SMTP_PORT";  tls=() ;;
  *) print -u2 -- "unknown notifications.email.smtp.security: $SMTP_SECURITY"; exit 2 ;;
esac

rcpt_args=()
while IFS= read -r addr; do
  [ -n "$addr" ] && rcpt_args+=(--mail-rcpt "$addr")
done <<< "$MAIL_TO_LINES"

curl --silent --show-error --max-time 45 --crlf "${tls[@]}" \
  --url "$url" \
  --user "$SMTP_USER:$SMTP_PASS" \
  --mail-from "$MAIL_FROM" \
  "${rcpt_args[@]}" \
  --upload-file "$message_file"
