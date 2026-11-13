#!/bin/bash
# PostToolUse hook (Bash): after a `git push`, shuts every simulator down and
# quits Simulator.app, which otherwise stay open and hold 50 to 70 % of the CPU.

command=$(/usr/bin/python3 -c 'import json, sys; print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))' 2>/dev/null)

printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|$)' || exit 0

booted=$(xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)')
simulator_app=$(pgrep -x Simulator)
[ "$booted" -eq 0 ] && [ -z "$simulator_app" ] && exit 0

xcrun simctl shutdown all >/dev/null 2>&1
[ -n "$simulator_app" ] && osascript -e 'quit app "Simulator"' >/dev/null 2>&1

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Push done: $booted simulator(s) shut down and Simulator.app quit (shutdown-simulators-after-push hook)."}}
EOF
