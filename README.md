# cleanX

**Clean up the disk space Xcode eats, and understand what you're deleting before you delete it.**

Xcode quietly piles up tens (sometimes hundreds) of GB: build caches, simulator clones, old iOS runtimes, device symbols and more. cleanX is an interactive terminal app that shows you where all that space went, explains in plain English what each thing is, gives you the **pros and cons of deleting it**, and cleans it up with a keypress.

```
  cleanX v1.0.0 · the Xcode disk-space cleaner

  #    What                                        Size   Safety
  ────────────────────────────────────────────────────────────────
  1    DerivedData (build cache)                12.4 GB   ● SAFE
  2    Parallel testing clones                 181.2 GB   ● SAFE
  3    Unavailable simulators                   11.0 GB   ● SAFE
  4    Simulator devices                        17.5 GB   ● CAUTION
  5    Simulator runtimes (iOS versions)        25.5 GB   ● CAUTION
  6    Device support files                     13.2 GB   ● SAFE
  ...
  13   Archives (App Store builds)               2.1 GB   ● RISKY
  ────────────────────────────────────────────────────────────────
  Total Xcode footprint                        265.3 GB
  Safe to clean right now                      218.9 GB
  Free disk space                                7.8 GB

[1-14] explain & clean  s clean all SAFE  r rescan  d dry-run off  q quit
>
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hlum/cleanX/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/hlum/cleanX.git && cd cleanX && ./install.sh
```

cleanX is a single Bash script with **no dependencies**. It runs on the bash that ships with macOS. It installs to `/usr/local/bin`, or to `~/.local/bin` if that isn't writable (set `PREFIX=/some/dir` to choose).

**Uninstall:**

```bash
curl -fsSL https://raw.githubusercontent.com/hlum/cleanX/main/install.sh | bash -s -- --uninstall
```

## Usage

```bash
cleanx              # interactive mode (recommended)
cleanx --scan       # just show what's using space
cleanx --dry-run    # interactive, but never deletes anything
cleanx --safe       # clean everything marked SAFE (asks once)
cleanx --safe --yes # same, no questions (good for cron)
```

In interactive mode:

| Key | Action |
|---|---|
| `1`–`14` | Explain that item (what it is, pros, cons), then clean it |
| `s` | Clean **all** SAFE items in one go |
| `d` | Toggle dry-run mode |
| `r` | Rescan |
| `q` | Quit |

For simulators, runtimes, device support, archives and old Xcodes, cleanX lists every entry with its size and lets you choose which to remove:

```
Your simulators
    1) iPhone 18 Pro                      iOS 27.0     Shutdown      17.5 MB
    2) iPhone 17                          iOS 27.0     Shutdown       5.5 GB
    3) iPad Pro 13-inch (M5)              iOS 27.0     Shutdown      17.0 MB
Select (e.g. 1 3 5-7 · all · keep 2 · Enter to cancel): keep 1
```

`keep 1` means "delete everything except #1".

## What each item is (and whether to delete it)

**● SAFE** means Xcode regenerates it automatically; the worst case is some rebuild or re-download time. **● CAUTION** means nothing breaks, but you lose data or have to re-download something big, so you choose. **● RISKY** means it can't be recreated.

| Item | Location | Safety | Pros of deleting | Cons of deleting |
|---|---|---|---|---|
| **DerivedData** | `~/Library/Developer/Xcode/DerivedData` | ● SAFE | Often the biggest win; fixes weird build/indexing bugs | Next build is a full rebuild, Xcode re-indexes |
| **Parallel testing clones** | `~/Library/Developer/XCTestDevices` | ● SAFE | Can reach hundreds of GB; useless after tests finish | None, recreated on the next parallel test run |
| **Unavailable simulators** | `~/Library/Developer/CoreSimulator/Devices` | ● SAFE | Removes dead devices whose runtime is gone | None, they can't boot anyway |
| **Simulator devices** | `~/Library/Developer/CoreSimulator/Devices` | ● CAUTION | Devices with apps/media can be several GB each | Apps, data and login state inside them are lost |
| **Simulator runtimes** | managed by `xcrun simctl runtime` | ● CAUTION | 5–10 GB per iOS version | Must re-download (GBs) to use that version again |
| **Device support files** | `~/Library/Developer/Xcode/*OS DeviceSupport` | ● SAFE | 3–7 GB per device model + OS version | Xcode re-copies symbols ("Preparing device…") on next connect |
| **SwiftUI Previews** | `~/Library/Developer/Xcode/UserData/Previews` | ● SAFE | Frees space and fixes stuck previews | First preview afterwards is slower |
| **Xcode & simulator caches** | `~/Library/Caches/com.apple.dt.Xcode`, `DocumentationCache`, `Products`, `CoreSimulator/Caches` | ● SAFE | General housekeeping | Rebuilt as needed |
| **Simulator & device logs** | `~/Library/Logs/CoreSimulator`, `*Device Logs` | ● SAFE | Pure clutter | Old logs gone |
| **Swift Package Manager cache** | `~/Library/Caches/org.swift.swiftpm` | ● SAFE | Frees space from unused packages | Packages re-download on next resolve |
| **CocoaPods cache** | `~/Library/Caches/CocoaPods` | ● SAFE | Frees space | Next `pod install` re-downloads |
| **Carthage cache** | `~/Library/Caches/org.carthage.CarthageKit` | ● SAFE | Frees space | Next bootstrap re-downloads |
| **Archives** | `~/Library/Developer/Xcode/Archives` | ● RISKY | Old builds nobody runs can go | **dSYMs are gone for good.** You can't symbolicate crash reports for that version. Keep archives for any live version. |
| **Other Xcode versions** | `/Applications/Xcode*.app` (never the active one) | ● CAUTION | 8–12+ GB each | Slow re-download if a project needs that version |

## Safety

- **Nothing is deleted without asking**, except with `--safe --yes`, which only touches SAFE items.
- **`--dry-run`** (or `d` in the menu) prints exactly what would be removed.
- A hard guard refuses to delete anything outside `~/Library/Developer`, `~/Library/Caches`, `~/Library/Logs` and `/Applications/Xcode*.app`, and refuses to cross into any other mounted filesystem.
- The active Xcode (`xcode-select -p`) is never offered for deletion.
- `~/Library/Developer/CoreDevice/DeviceFS` is deliberately **not** included. It *looks* like a huge cache, but it's a virtual filesystem that mirrors files on your connected iPhone. It uses no space on your Mac, and deleting from it would target the device.
- Quit Xcode and Simulator before cleaning so files aren't in use (cleanX warns you).

## Limitations

- Some items live in root-owned, SIP-protected locations and need manual cleanup with `sudo`. That includes legacy simulator runtimes that `xcrun simctl runtime list` doesn't show, and the shared simulator cache in `/Library/Developer/CoreSimulator/Caches/dyld`. For runtimes, the easiest route is Xcode › Settings › Components.
- APFS can take a minute to report reclaimed space, so the "Freed" number may lag.

## License

MIT
