#!/system/bin/sh
# Runs in Magisk's late_start service stage (already root, no su needed)

INPUT_NODE="/sys/class/input/input2/inhibited"
BACKLIGHT_NODE="/sys/class/backlight/sprd_backlight/brightness"

# Wait briefly for the nodes to exist, in case they appear late during boot
for i in $(seq 1 30); do
    [ -e "$INPUT_NODE" ] && [ -e "$BACKLIGHT_NODE" ] && break
    sleep 1
done

[ -e "$INPUT_NODE" ] && echo 1 > "$INPUT_NODE"
[ -e "$BACKLIGHT_NODE" ] && echo 0 > "$BACKLIGHT_NODE"
