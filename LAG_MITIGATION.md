# Lag-Induced Multiple Key Input Mitigation

This implementation adds lag-induced multiple key input mitigation to the WDK_KeyboardFilter driver.

## Problem
When system lag occurs, a single physical key press may be interpreted as multiple key events by the system, causing unwanted repeated characters or actions.

## Solution
The driver now implements a time-based duplicate key detection system that filters out duplicate key press events that occur within a configurable threshold time window.

## Implementation Details

### Key Components
1. **KEY_EVENT_TRACKER structure**: Tracks recent key events with timestamps
2. **IsLagInducedDuplicate()**: Checks if a key event is a duplicate within the threshold
3. **Modified kbReadComplete()**: Filters key events before passing to system
4. **Thread-safe tracking**: Uses spin locks for concurrent access protection

### Configuration
- **LAG_MITIGATION_THRESHOLD_MS**: Default 50ms threshold for duplicate detection
- **MAX_TRACKED_KEYS**: Maximum 256 recent key events tracked

### Behavior
- Only **key press events** (Flags=0) are checked for duplicates
- **Key release events** (Flags=1) always pass through
- **Different keys** in rapid sequence are allowed
- **Same key** within threshold time is filtered as duplicate
- **Memory efficient**: Uses circular buffer for key tracking

### Debug Output
- Normal key events: "键盘过滤驱动:[key]"
- Filtered duplicates: "键盘过滤驱动:已过滤重复按键:[key]"

## Testing
The implementation has been tested with a simulation that validates:
- Normal key presses pass through
- Immediate duplicates are filtered
- Key releases are never filtered
- Time-based threshold works correctly
- Array wraparound handling
- Thread safety considerations

## Performance Impact
- Minimal overhead: O(n) search where n ≤ 256
- Efficient memory usage: Fixed-size circular buffer
- Thread-safe with spin lock protection
- No heap allocations in hot path (except for temporary filtering buffer)