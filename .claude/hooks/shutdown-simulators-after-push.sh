#!/bin/bash
# Hook PostToolUse (Bash) : après un `git push` réussi, éteint tous les
# simulateurs et quitte Simulator.app, qui sinon restent ouverts et occupent
# 50 à 70 % du processeur.

command=$(/usr/bin/python3 -c 'import json, sys; print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))' 2>/dev/null)

printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|$)' || exit 0

booted=$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)')
simulator_app=$(pgrep -x Simulator)
[ "$booted" -eq 0 ] && [ -z "$simulator_app" ] && exit 0

xcrun simctl shutdown all >/dev/null 2>&1
[ -n "$simulator_app" ] && osascript -e 'quit app "Simulator"' >/dev/null 2>&1

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Push terminé : $booted simulateur(s) éteint(s) et Simulator.app fermé automatiquement (hook shutdown-simulators-after-push)."}}
EOF
