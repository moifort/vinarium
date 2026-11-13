---
name: ios-simulator
description: Use when a simulator runtime or platform must be downloaded, a download stays on "Preparing to download", or a simulator crashes at boot or launch. The long form of the Xcode and simulators part of stack rule 15-tooling.
---

# Simulator runtimes and crashes

The rule (stack rule 15-tooling) says: the runtime already on the machine, never a download
without asking, one simulator at a time, booted through the simulator tool or Simulator.app.
This is how, and what the traps were.

## Downloading a runtime or a platform

Only after the person said yes, and only the version matching the installed SDK
(`xcodebuild -showsdks`).

1. `pgrep -f downloadPlatform` first: several downloads at once block each other on "Preparing
   to download", without a byte transferred.
2. From the command line, never through Xcode's UI: `xcodebuild -downloadPlatform <name>`.
3. Progress is the size of `/Library/Developer/CoreSimulator/Volumes`
   (`du -sh /Library/Developer/CoreSimulator/Volumes`), not the program's messages, which say
   nothing useful.

## A download stuck on "Preparing to download"

No byte transferred and no error: the network first. macOS suspends system asset downloads on a
connection it considers cellular, an iPhone hotspot included, silently: the daemon does not
refuse, it waits for an acceptable network. Check the interface and the Wi-Fi name before
anything else (`route -n get default | grep interface`,
`system_profiler SPAirPortDataType | grep -A1 "Current Network"`); a Wi-Fi network named after
an iPhone settles it. The daemon is not broken: one at 0% CPU for days is normal, and neither
killing it nor a reboot changes anything.

## A crash at boot or launch

A device booted without a display, by `xcrun simctl boot` alone, made SpringBoard crash in a
loop (`EXC_BREAKPOINT` in `FBSDisplayMonitor`, at display initialisation), with a crash report
window each time. Hence the rule: boot through the simulator tool (`attach`, `launch`) or
Simulator.app; when `simctl boot` is the only way, `attach` right after.

The signs of a crash: a `simctl launch` answering "The system shell probably crashed", or a new
`SpringBoard-*.ips` in `~/Library/Logs/DiagnosticReports`. Then `xcrun simctl shutdown <udid>`
at once, no second launch, and tell the person before any new attempt.
