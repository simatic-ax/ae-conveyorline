# Reset Mechanism Integration

## Overview
The reset mechanism from the `@simatic-ax/automationbase` library has been successfully integrated into the conveyor system. This provides centralized reset control for all 32 conveyors.

## What Was Added

### 1. Global Reset Manager
A `GlobalResetManager` instance of type [`ResetCommandManager`](.apax/packages/@simatic-ax/automationbase/src/Equipment/ResetCommandManager.st:7) was added to manage reset commands for all conveyors.

**Location:** [`Configuration.st`](../src/Configuration.st:28)

```st
// Global reset command manager (shared by all conveyors)
GlobalResetManager : ResetCommandManager;
```

### 2. Reset Button Control
A `ResetButton` variable of type `BinSignal` from `@simatic-ax/io` library was added to trigger reset operations from HMI or external control.

**Location:** [`Configuration.st`](../src/Configuration.st:18)

```st
// Reset button for all conveyors (BinSignal from @simatic-ax/io)
ResetButton : BinSignal;
```

**Physical I/O Mapping:** [`Configuration.st`](../src/Configuration.st:273)

```st
// Physical I/O for Reset Button
HW_ResetButton AT %I4.0 : BOOL;
```

### 3. Conveyor Configuration
All 32 conveyors (Conveyor1-Conveyor32) were connected to the `GlobalResetManager` by adding the `ResetCommand` parameter to their initialization.

**Example from [`Configuration.st`](../src/Configuration.st:142):**
```st
Conveyor1 : ConveyorBase := (
    Name := 'Conveyor_1', 
    StopSensor := StopSensor1, 
    Motor := Motor1, 
    NextConveyor := Conveyor2, 
    PrevConveyor := NULL, 
    OffDelayTime := T#5s, 
    NormalSpeed := 1.5, 
    SlowSpeed := 0.5, 
    Mode := GlobalOpMode, 
    ExternalRelease := GlobalRelease, 
    ResetCommand := GlobalResetManager  // <-- Added
);
```

### 4. Reset Logic in Main Program
Reset handling logic was added to [`MainProgram.st`](../src/MainProgram.st:309) to trigger and manage reset operations.

```st
// 1. Read reset button input
ResetButton.ReadCyclic(signal := HW_ResetButton);

// 2. Handle reset command for all conveyors
IF ResetButton.Q() THEN
    GlobalResetManager.TriggerReset();
ELSE
    GlobalResetManager.ClearResetTrigger();
END_IF;
```

**Note:** The `ResetButton` is a `BinSignal` that must be read cyclically with `ReadCyclic()`, and its value is accessed via the `Q()` method.

### 5. Reset Manager Cyclic Execution
The reset manager's `RunCyclic()` method is called after all equipment execution to complete the reset cycle.

**Location:** [`MainProgram.st`](../src/MainProgram.st:539)

```st
// 5. Execute reset manager cyclic (MUST be called after all equipment)
GlobalResetManager.RunCyclic();
```

## How It Works

### Reset Mechanism Flow

1. **Trigger**: When `ResetButton` is set to TRUE, the `GlobalResetManager.TriggerReset()` method is called
2. **Registration Phase**: All conveyors check for reset command via `GetResetCommand()`
3. **Acknowledgment Phase**: Only conveyors with errors call `AcknowledgeReset()`
4. **Completion Phase**: The reset manager completes the cycle after all equipment have been processed
5. **Clear**: When `ResetButton` is set to FALSE, the trigger is cleared

### Three-Cycle Process

The reset manager uses a three-phase cycle:
- **Cycle 1**: Registration - counts how many equipment check for reset
- **Cycle 2**: Acknowledgment - equipment with errors acknowledge the reset
- **Cycle 3**: Completion - reset is finalized and flags are cleared

### Automatic Error Handling

Since [`ConveyorBase`](.apax/packages/@simatic-ax/conveyor/src/Conveyor/ConveyorBase.st:28) extends [`EquipmentBase`](.apax/packages/@simatic-ax/automationbase/src/Equipment/EquipmentBase.st:20), it automatically:
- Checks for reset commands during `RunCyclic()`
- Calls `ResetFault()` when a reset is triggered and the conveyor has an error
- Acknowledges the reset to the manager
- Clears error states and messages

## Usage

### From HMI or External Control

Set the physical input `HW_ResetButton` (mapped to %I4.0) to TRUE to reset all conveyors with errors. The `ResetButton` BinSignal will read this input cyclically and trigger the reset manager.

The reset will automatically:
- Clear error states on all conveyors that have errors
- Reset internal fault conditions
- Allow conveyors to resume normal operation

**Example:** Connect a physical button to input %I4.0, or set it manually in the watch window:
```st
HW_ResetButton := TRUE;  // Trigger reset for all conveyors
```

### Monitoring Reset Status

The reset manager provides several monitoring methods:

```st
// Check if reset is currently active
isActive := GlobalResetManager.IsResetPending();

// Get number of conveyors that checked for reset
registeredCount := GlobalResetManager.GetRegisteredEquipmentCount();

// Get number of conveyors that acknowledged (had errors)
acknowledgedCount := GlobalResetManager.GetAcknowledgmentCount();

// Check if reset cycle is complete
isComplete := GlobalResetManager.IsResetComplete();
```

## Benefits

1. **Centralized Control**: Single reset button controls all 32 conveyors
2. **Selective Reset**: Only conveyors with errors are reset, others continue normally
3. **Automatic Tracking**: The manager automatically tracks which conveyors need reset
4. **Consistent Architecture**: Follows the same pattern as `OperatingModeManager`
5. **No Manual Intervention**: Equipment automatically participates in reset cycles

## Integration with Existing Systems

The reset mechanism integrates seamlessly with:
- **Operating Mode Manager**: Works alongside automatic/manual mode switching
- **Release Mechanism**: Cooperates with the global release signal
- **Conveyor Chain**: Respects the conveyor predecessor/successor relationships
- **Motor Control**: Ensures motors are properly stopped during reset

## Testing

To test the reset mechanism:

1. Simulate an error condition on one or more conveyors
2. Set `ResetButton := TRUE` in the watch window
3. Observe that only conveyors with errors are reset
4. Verify that `GlobalResetManager.GetAcknowledgmentCount()` matches the number of conveyors with errors
5. Set `ResetButton := FALSE` to clear the trigger

## References

- [`ResetCommandManager`](.apax/packages/@simatic-ax/automationbase/src/Equipment/ResetCommandManager.st) - Central reset manager class
- [`IResetCommand`](.apax/packages/@simatic-ax/automationbase/src/Equipment/IResetCommand.st) - Reset command interface
- [`EquipmentBase`](.apax/packages/@simatic-ax/automationbase/src/Equipment/EquipmentBase.st) - Base equipment class with reset support
- [ResetCommandExample](.apax/packages/@simatic-ax/automationbase/examples/ResetCommandExample.st) - Example usage from automationbase library
