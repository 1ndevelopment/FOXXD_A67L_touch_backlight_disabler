# Disable Input2 + Backlight — Magisk Module

A minimal Magisk module that, on every boot, does the equivalent of:

```sh
su -c "
echo 1 > /sys/class/input/input2/inhibited
echo 0 > /sys/class/backlight/sprd_backlight/brightness
"
```

## What it does

- Writes `1` to `/sys/class/input/input2/inhibited` — disables the input device registered as `input2` (commonly a touchscreen or digitizer on some Spreadtrum/Unisoc devices).
- Writes `0` to `/sys/class/backlight/sprd_backlight/brightness` — forces the `sprd_backlight` panel brightness to zero.

Together these are typically used to keep a screen fully dark and unresponsive to touch (e.g. an always-on secondary display, a screen you want physically off while the device stays awake).

## How it works

- Magisk modules already execute `service.sh` as root, so no `su -c` wrapper is needed — this module runs the two `echo` commands directly.
- `service.sh` runs at Magisk's `late_start service` stage (after boot has mostly completed).
- The script waits up to 30 seconds for both sysfs paths to appear before writing, then applies the settings only if each path exists. If a path is missing (e.g. different hardware), that step is silently skipped instead of erroring.

## Files

| File | Purpose |
|---|---|
| `module.prop` | Module metadata (id, name, version) shown in Magisk Manager. |
| `service.sh` | The script that performs the two writes at boot. |
| `META-INF/com/google/android/update-binary` | Standard Magisk installer boilerplate. |
| `META-INF/com/google/android/updater-script` | Standard Magisk marker file (`#MAGISK`). |

## Installation

1. Copy `input2_backlight_disable.zip` to your device.
2. Open **Magisk Manager** → **Modules** → **Install from storage**.
3. Select the zip and flash it.
4. Reboot.

## Verifying it worked

After rebooting, check the values directly:

```sh
su -c "cat /sys/class/input/input2/inhibited"
# should print: 1

su -c "cat /sys/class/backlight/sprd_backlight/brightness"
# should print: 0
```

## Uninstalling

Remove the module from Magisk Manager's **Modules** tab and reboot. This restores default behavior for both the input device and the backlight (no other files on the system are modified).

## Notes / caveats

- **Device-specific paths**: `input2` and `sprd_backlight` are not universal — the exact input node number and backlight driver name depend on your device's kernel. Confirm these paths exist on your device (`ls /sys/class/input/`, `ls /sys/class/backlight/`) before relying on this module; if they differ, edit `service.sh` accordingly and reflash.
- **Re-flashing after edits**: Any changes to `service.sh` require re-zipping the module and reflashing (or editing directly in `/data/adb/modules/<id>/service.sh` and rebooting).
- Setting brightness to `0` via this raw sysfs node bypasses the normal Android brightness stack — this is intentional here but means the system UI's brightness slider won't reflect or control it.
