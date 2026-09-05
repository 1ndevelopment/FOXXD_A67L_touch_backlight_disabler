# Disable Input2 + Backlight - Magisk Module

A minimal Magisk module that, on every boot, does the equivalent of:

```sh
su -c "
echo 1 > /sys/class/input/input2/inhibited
echo 0 > /sys/class/backlight/sprd_backlight/brightness
"
```

## What it does

- Writes `1` to `/sys/class/input/input2/inhibited` - disables the input device registered as `input2` (commonly a touchscreen or digitizer on some Spreadtrum/Unisoc devices).
- Writes `0` to `/sys/class/backlight/sprd_backlight/brightness` - forces the `sprd_backlight` panel brightness to zero.

Together these are typically used to keep a screen fully dark and unresponsive to touch (e.g. an always-on secondary display, or a screen you want physically off while the device stays awake).

## How it works

- Magisk modules already execute `service.sh` as root, so no `su -c` wrapper is needed - this module runs the two `echo` commands directly.
- `service.sh` runs at Magisk's `late_start service` stage (after boot has mostly completed).
- The script waits up to 30 seconds for both sysfs paths to appear, checking once per second, and breaks out early as soon as both exist.
- Each write is attempted independently and its success is logged. If a path never appears, or a write fails (e.g. due to permissions or a read-only node), that's logged as an error rather than failing silently.
- Logs are tagged `disable-input-backlight` and can be viewed with:
  ```sh
  adb logcat -s disable-input-backlight
  ```

## Requirements

- A rooted device with Magisk installed.
- A kernel that exposes both sysfs paths referenced above (see **Notes / caveats** if your device differs).
- `service.sh` uses only POSIX shell built-ins (no `seq`), so it works under Android's minimal toolbox/busybox shell without extra dependencies.

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

If either value looks wrong, check the logs for what happened during boot:

```sh
adb logcat -s disable-input-backlight
```

Expected log lines look like:

```
input node inhibited: /sys/class/input/input2/inhibited
backlight set to 0: /sys/class/backlight/sprd_backlight/brightness
```

An `ERROR:` line instead tells you whether the node never appeared (wrong path for your device) or the write itself failed (permissions or a read-only node).

## Uninstalling

Remove the module from Magisk Manager's **Modules** tab and reboot. This restores default behavior for both the input device and the backlight - no other files on the system are modified.

## Notes / caveats

- **Device-specific paths**: `input2` and `sprd_backlight` are not universal - the exact input node number and backlight driver name depend on your device's kernel. Confirm these paths exist on your device before relying on this module:
  ```sh
  ls /sys/class/input/
  ls /sys/class/backlight/
  ```
  If they differ, edit `service.sh` accordingly and reflash (or edit in place - see below).
- **Re-flashing after edits**: any change to `service.sh` requires re-zipping the module and reflashing, or editing directly in `/data/adb/modules/<id>/service.sh` and rebooting - no re-flash needed for the latter.
- **Bypasses the Android brightness stack**: setting brightness to `0` via this raw sysfs node is intentional here, but it means the system UI's brightness slider won't reflect or control it, and other brightness-related logic (auto-brightness, other apps) may not see this change either.
- **Persists until next boot**: these are runtime sysfs writes, not permanent kernel config changes. Uninstalling the module (or a kernel/firmware update) fully reverts behavior.
- **OTA updates may break paths**: a system update can renumber input nodes or rename the backlight driver. If the module silently stops working after an OTA, re-check the paths above first.
- 
