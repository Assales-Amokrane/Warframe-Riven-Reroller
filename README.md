# Warframe Riven Reroller

AutoHotkey v2 automation for rerolling Warframe Rivens from a JSON rule profile.

The app reads Riven attributes with OCR, evaluates the current and incoming rolls against the configured profile, and picks the better result automatically.

## Links

- Riven Configurator: https://rivenconfigurator.up.railway.app

## Quick Start

1. Launch `dist/Riven Reroller.exe` or run `Riven Reroller Release.ahk`.
2. Press `F8`, load a JSON profile, and set the maximum rerolls for this session on the overview page.
3. Open the Warframe Riven reroll screen and make sure the game window can be focused.
4. Press `F9` to start the reroll loop.
5. Press `F10` to stop or `Esc` to exit.

If you use the dev script instead of the release build, the last loaded profile is remembered locally and reloaded on startup when possible.

## Features

- OCR-based reading of old and new Riven attributes
- State detection for the reroll, confirm, and selection screens
- Rule-based comparison using `mandatory`, `desired`, `undesired`, and `indifferent` slots
- Automatic keep/reject choice between the current and incoming Riven
- Optional stop when a perfect Riven is found
- Dev-only logging, OCR capture output, test hotkeys, and unit tests

## Requirements

- Windows
- Warframe installed and able to be focused by the script
- AutoHotkey v2 if you want to run the `.ahk` sources directly
- A compatible exported JSON profile

Notes:

- Base coordinates were authored for a 1920x1080 layout and are scaled at runtime.
- The dev script supports an optional local coordinate override file at `config/coordinate-profile.json`.
- The release build is intended for normal use. The dev build includes extra debug tooling.

## Files

- `dist/Riven Reroller.exe`: compiled release build
- `Riven Reroller Release.ahk`: release entrypoint
- `Riven Reroller.ahk`: dev entrypoint with tests and debug hotkeys
- `build-release.ps1`: PowerShell build script for recreating the EXE

## Hotkeys

Release build:

- `F8`: load or change profile
- `F9`: start reroll loop
- `F10`: stop reroll loop
- `Esc`: exit

Dev build only:

- `F1`: test main state detection
- `F2`: test confirm cycle detection
- `F3`: test confirm selection detection
- `F4`: test the combined state detector
- `F5`: show OCR/state overlay areas
- `F6`: run unit tests
- `F11`: show the current Riven evaluation summary

## Profile Format

The app expects a JSON bundle with:

- root metadata such as `schemaVersion`, `appVersion`, `weaponId`, and `weaponName`
- `profile.rules.positiveSlots` as exactly 3 rule slots
- `profile.rules.negativeSlot` as a single rule slot

Each slot uses:

- `mode`: `mandatory`, `desired`, `undesired`, or `indifferent`
- `attrIds`: an array of attribute ids for `mandatory` and `desired`; `indifferent` and `undesired` clear and ignore `attrIds`

The loader validates the schema version, slot structure, and attribute ids before enabling rerolling.

Rule behavior:

- `mandatory`: the slot must match one of its selected attributes or the Riven is rejected
- `desired`: the slot is optional; matching one of its selected attributes adds score
- `negativeSlot` with `mode: "desired"` is treated as an allow-list when a negative attribute is present; a non-matching negative is rejected
- `indifferent`: the slot is ignored completely
- `undesired`: slot-level only; `positiveSlots[3]` rejects any third positive and `negativeSlot` rejects any negative attribute
- `Weapon Recoil` is special-cased to match Warframe semantics: `-Weapon Recoil` counts as a positive attribute, while `+Weapon Recoil` counts as a negative attribute
- profiles that want reduced recoil should include `weapon-recoil` in a positive slot, not in `negativeSlot`

Comparison order:

- valid Rivens are compared by mandatory matches first, then desired matches
- in practice, any valid Riven has already satisfied all configured mandatory slots, so desired matches usually decide ties

Current configurator `undesired` behavior is slot-level:

- `positiveSlots[3]` with `mode: "undesired"` means the Riven must not have a third positive attribute
- `negativeSlot` with `mode: "undesired"` means the Riven must not have a negative attribute
- `positiveSlots[1]` and `positiveSlots[2]` cannot use `undesired`

This repository does not generate profile JSON by itself; it only consumes exported profiles from the configurator linked above.

## Development

Run the dev script:

```powershell
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" ".\Riven Reroller.ahk"
```

Useful dev behavior:

- writes logs to `logs/`
- can save OCR captures to `logs/attribute-captures/`
- remembers the last loaded profile in `config/last-profile.txt`
- supports optional coordinate overrides in `config/coordinate-profile.json`

## Running Tests

From the dev script, press `F6` to run the built-in unit tests.

The tests cover:

- OCR attribute-line parsing helpers
- decision logic
- state-text classification
- profile slot validation

## Building The EXE

Use the included build script:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-release.ps1
```

Default output:

```text
dist\Riven Reroller.exe
```

The script expects a standard AutoHotkey v2 installation, including `Ahk2Exe.exe`.

## Project Layout

- `modules/Actions.ahk`: click actions and Warframe window activation
- `modules/Config.ahk`: runtime settings, coordinates, attribute catalog
- `modules/Decision.ahk`: Riven comparison logic
- `modules/MainLoop.ahk`: reroll state machine
- `modules/OCR.ahk`: OCR library wrapper
- `modules/ProfileLoader.ahk`: profile loading, validation, overview UI
- `modules/RivenAttributes.ahk`: OCR preprocessing and attribute parsing
- `modules/StateDetection.ahk`: UI state detection
- `modules/Tests.ahk`: unit tests
- `modules/TestingHotkeys.ahk`: dev-only visual/debug helpers

## Caution

This project automates mouse input and screen reading inside Warframe. Use it only when you understand the current coordinates, profile, and window setup well enough to trust the automation.

## License

See `LICENSE`.
