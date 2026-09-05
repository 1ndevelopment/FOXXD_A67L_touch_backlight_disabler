#!/system/bin/sh
# Runs in Magisk's late_start service stage (already root, no su needed)
# Purpose: disable a specific input device and turn off the backlight
# (e.g. for a secondary/cover screen you never want lit or touchable).

LOG_TAG="disable-input-backlight"
INPUT_NODE="/sys/class/input/input2/inhibited"
BACKLIGHT_NODE="/sys/class/backlight/sprd_backlight/brightness"
MAX_WAIT=30

log() {
    log -t "$LOG_TAG" "$1" 2>/dev/null
}

# Wait for the nodes to exist, in case they appear late during boot.
# Exit the loop as soon as both are present rather than always sleeping the full time.
i=0
while [ "$i" -lt "$MAX_WAIT" ]; do
    [ -e "$INPUT_NODE" ] && [ -e "$BACKLIGHT_NODE" ] && break
    i=$((i + 1))
    sleep 1
done

if [ -e "$INPUT_NODE" ]; then
    if echo 1 > "$INPUT_NODE" 2>/dev/null; then
        log "input node inhibited: $INPUT_NODE"
    else
        log "ERROR: failed to write to $INPUT_NODE"
    fi
else
    log "ERROR: $INPUT_NODE never appeared after ${MAX_WAIT}s"
fi

if [ -e "$BACKLIGHT_NODE" ]; then
    if echo 0 > "$BACKLIGHT_NODE" 2>/dev/null; then
        log "backlight set to 0: $BACKLIGHT_NODE"
    else
        log "ERROR: failed to write to $BACKLIGHT_NODE"
    fi
else
    log "ERROR: $BACKLIGHT_NODE never appeared after ${MAX_WAIT}s"
fi
