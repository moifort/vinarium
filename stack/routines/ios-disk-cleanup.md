---
id: ios-disk-cleanup
scope: machine
runtime: desktop
cadence: "0 10 * * 1"
title: iOS disk cleanup (weekly)
---

Free the disk space iOS development takes on this Mac. Report in the person's language, in three
to five lines.

1. Unless an `xcodebuild` or `swift-build` is running (then stop and say so), run the cleanup
   below exactly, and nothing else:

   ```zsh
   free_gb() { df -g / | awk 'NR==2 {print $4}'; }
   echo "free before: $(free_gb) GB"
   # Derived data of projects untouched for seven days.
   find ~/Library/Developer/Xcode/DerivedData -mindepth 1 -maxdepth 1 -type d -mtime +7 -print -exec rm -rf {} +
   # Simulators whose runtime is no longer installed.
   xcrun simctl delete unavailable
   # Swift package repositories and artifacts untouched for thirty days.
   for dir in ~/Library/Caches/org.swift.swiftpm/{repositories,artifacts}; do
     [[ -d $dir ]] && find "$dir" -mindepth 1 -maxdepth 1 -mtime +30 -print -exec rm -rf {} +
   done
   # Xcode caches and simulator logs.
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/* ~/Library/Logs/CoreSimulator/* 2>/dev/null
   echo "free after: $(free_gb) GB"
   ```

2. Measure what is left: `du -sh ~/Library/Developer/Xcode/DerivedData
   ~/Library/Developer/CoreSimulator/Devices ~/Library/Caches/org.swift.swiftpm`,
   `du -xhd1 /System/Volumes/Data/private/tmp | sort -h | tail -5`, `xcrun simctl runtime list`
   and `xcodebuild -showsdks`.
3. Report the free space before and after, what went, and any anomaly: more than one simulator
   runtime for a platform (only the newest, matching the installed Xcode's SDK, is kept: name the
   one to delete and its size), a runtime older than the SDK, derived data still above 20 GB,
   `/tmp` above 10 GB (name its largest folders: derived data paths left by builds).

## Never

- Delete anything beyond the commands above: never a simulator runtime, an Xcode archive
  (`~/Library/Developer/Xcode/Archives`), a project file or a folder under `/tmp`. Report them.
- Download a runtime or a platform.
- Launch a subagent.
