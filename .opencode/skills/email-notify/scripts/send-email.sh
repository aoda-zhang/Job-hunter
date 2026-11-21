#!/bin/zsh
# Send one plain-text email using job-hunter.config.json.
# Supported backends: mailapp, smtp, resend.
set -u
setopt NULL_GLOB

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CONFIG="${JOB_HUNTER_CONFIG:-$REPO/job-hunter.config.json}"

if [ ! -r "$CONFIG" ]; then
  print -u2 -- "config not found: $CONFIG"
  exit 2
fi
command -v jq >/dev/null 2>&1 || { print -u2 -- "jq is required"; exit 2; }

field() { jq -r "$1" "$CONFIG"; }

enabled="$(field '.notifications.email.enabled // false')"
if [ "$enabled" != "true" ]; then
  print -u2 -- "email notifications are disabled in $CONFIG"
  exit 3
fi

BACKEND="$(field '.notifications.email.backend // "smtp"')"
MAIL_TO_JSON="$(field '.notifications.email.to // []')"
if ! print -r -- "$MAIL_TO_JSON" | jq -e 'type == "array" and length > 0 and all(.[]; type == "string" and length > 0)' >/dev/null; then
  print -u2 -- "notifications.email.to must be a non-empty array of email addresses"
  exit 2
fi
MAIL_TO_JOINED="$(print -r -- "$MAIL_TO_JSON" | jq -r 'join(", ")')"
MAIL_TO_LINES="$(print -r -- "$MAIL_TO_JSON" | jq -r '.[]')"
MAIL_FROM="$(field '.notifications.email.from // empty')"

case "$BACKEND" in
  mailapp)
    command -v osascript >/dev/null 2>&1 || { print -u2 -- "osascript is required"; exit 2; }
    if [ "$1" = "--check" ]; then
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
    [ -n "$MAIL_FROM" ] || MAIL_FROM="$SMTP_USER"
    missing=()
    [ -n "$MAIL_FROM" ] || missing+=(MAIL_FROM)
    [ -n "$SMTP_HOST" ] || missing+=(SMTP_HOST)
    [ -n "$SMTP_USER" ] || missing+=(SMTP_USER)
    [ -n "$SMTP_PASS" ] || missing+=(SMTP_PASS)
    if [ $#missing -gt 0 ]; then
      print -u2 -- "missing email settings: $missing"
      exit 2
    fi
    if [ "$1" = "--check" ]; then
      print -r -- "email config OK: SMTP $SMTP_USER -> $MAIL_TO_JOINED via $SMTP_HOST:$SMTP_PORT ($SMTP_SECURITY)"
      exit 0
    fi
    ;;
  resend)
    command -v security >/dev/null 2>&1 || { print -u2 -- "macOS security command is required for Resend Keychain access"; exit 2; }
    command -v curl >/dev/null 2>&1 || { print -u2 -- "curl is required"; exit 2; }
    RESEND_SERVICE="$(field '.notifications.email.resend.keychainService // "jobhunter-resend-api-key"')"
    KEYCHAIN_ACCOUNT="$(id -un)"
    RESEND_API_KEY="$(security find-generic-password -a "$KEYCHAIN_ACCOUNT" -s "$RESEND_SERVICE" -w 2>/dev/null || true)"
    if [ -z "$RESEND_API_KEY" ]; then
      print -u2 -- "Resend API key not found in macOS Keychain (service: $RESEND_SERVICE, account: $KEYCHAIN_ACCOUNT)"
      print -u2 -- "See the setup instructions in .opencode/skills/email-notify/SKILL.md"
      exit 2
    fi
    [ -n "$MAIL_FROM" ] || { print -u2 -- "notifications.email.from is required for Resend"; exit 2; }
    if [ "$1" = "--check" ]; then
      print -r -- "email config OK: Resend -> $MAIL_TO_JOINED (sender: $MAIL_FROM; API key found in Keychain)"
      exit 0
    fi
    ;;
  *)
    print -u2 -- "unknown notifications.email.backend: $BACKEND (use mailapp, smtp or resend)"
    exit 2
    ;;
esac

subject="$1"
[ -n "$subject" ] || subject="Job Hunter notification"
body_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-mail.XXXXXX")"
message_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-msg.XXXXXX")"
payload_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-payload.XXXXXX")"
auth_file="$(mktemp "${TMPDIR:-/tmp}/jobhunter-auth.XXXXXX")"
trap 'rm -f "$body_file" "$message_file" "$payload_file" "$auth_file"' EXIT
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

if [ "$BACKEND" = "resend" ]; then
  jq -n --arg from "$MAIL_FROM" --arg subject "$subject" --rawfile text "$body_file" --argjson to "$MAIL_TO_JSON" \
    '{from: $from, to: $to, subject: $subject, text: $text}' > "$payload_file"
  # Keep the bearer token out of process arguments; temp files are private.
  printf 'header = "Authorization: Bearer %s"\n' "$RESEND_API_KEY" > "$auth_file"
  chmod 600 "$auth_file" "$payload_file"
  response="$(curl --silent --show-error --max-time 45 --config "$auth_file" \
    --header "Content-Type: application/json" --data-binary "@$payload_file" \
    --write-out $'\n%{http_code}' https://api.resend.com/emails 2>&1)"
  curl_exit=$?
  if [ "$curl_exit" -ne 0 ]; then
    print -u2 -- "Resend request failed (curl exit $curl_exit): $response"
    exit "$curl_exit"
  fi
  status_code="${response##*$'\n'}"
  response_body="${response%$'\n'*}"
  if [[ "$status_code" != 2?? ]]; then
    print -u2 -- "Resend API request failed (HTTP $status_code): $response_body"
    exit 1
  fi
  email_id="$(print -r -- "$response_body" | jq -r '.id // empty' 2>/dev/null)"
  if [ -n "$email_id" ]; then
    print -r -- "email accepted by Resend (id: $email_id)"
  else
    print -r -- "email accepted by Resend"
  fi
  exit 0
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
curl --silent --show-error --max-time 45 --crlf "$tls[@]" \
  --url "$url" --user "$SMTP_USER:$SMTP_PASS" --mail-from "$MAIL_FROM" \
  "$rcpt_args[@]" --upload-file "$message_file"
