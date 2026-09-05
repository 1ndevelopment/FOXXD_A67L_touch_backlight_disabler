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

## Recovery if you get locked out

If `input2` turns out to be your primary touchscreen (or the only way you have of interacting with the device), you can end up unable to unlock or navigate the phone after this module loads. Here's how to recover, roughly in order of how likely you are to have it available:

1. **ADB (fastest, if already enabled)**
   If USB debugging was on before you flashed the module, connect the device to a PC and remove the module without touching the screen:
   ```sh
   adb shell magisk --remove-modules
   ```
   or, to disable only this module:
   ```sh
   adb shell touch /data/adb/modules/touchscreen_backlight_disabler/disable
   ```
   Then reboot:
   ```sh
   adb reboot
   ```

2. **Magisk's "disable all modules" boot combo**
   Most Magisk-patched devices support forcing a boot with all modules disabled by holding a volume key during boot:
   - Power off the device fully.
   - Power on, and as soon as you see the boot logo/animation, hold **Volume Down** (some devices use **Volume Up**) until it finishes booting.
   - This boots with all Magisk modules disabled, restoring normal touch input so you can uninstall the module properly from Magisk Manager.
   - Exact key and timing vary by device/ROM - check your device's XDA thread if this doesn't work on the first try.

3. **Recovery mode (TWRP or stock recovery)**
   If you have a custom recovery like TWRP installed:
   - Boot into recovery (usually Power + Volume Up, or Power + Volume Down depending on device).
   - Use TWRP's file manager or terminal to delete or disable the module directory:
     ```sh
     rm -rf /data/adb/modules/touchscreen_backlight_disabler
     ```
   - Reboot to system.

4. **Fastboot + `boot.img` or a full reflash**
   As a last resort, boot into fastboot mode and either:
   - Flash a Magisk-unpatched boot image to temporarily drop root (this alone won't remove the module's files, but with root gone the sysfs writes never run, restoring touch), then use ADB or a file manager to remove `/data/adb/modules/<module_id>` before repatching, or
   - Perform a full factory reset if no other option is available (this wipes user data - genuinely last resort).

**Prevention is easier than recovery** - before relying on this module, always confirm `input2` is *not* your primary touchscreen, and keep USB debugging enabled and a PC with `adb`/`fastboot` on hand while testing.

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
