# Conveyor Line Implementation

## Overview

This project implements a complete conveyor line consisting of **three conveyors** from the `@simatic-ax/conveyor` package. The conveyors are linked together to form a material transport line where material flows from Conveyor 1 → Conveyor 2 → Conveyor 3, with full motor control and I/O integration.

## Architecture

### Conveyor Configuration

The conveyor line consists of three `ConveyorBase` instances:

1. **Conveyor 1** (Entry conveyor)
   - Name: `Conveyor_1`
   - Motor: `Motor1`
   - Previous conveyor: None (entry point)
   - Next conveyor: Conveyor 2
   - Stop sensor: StopSensor1 (mapped to %I0.0)
   - Motor output: HW_Motor1_Run (mapped to %Q0.0)

2. **Conveyor 2**
   - Name: `Conveyor_2`
   - Motor: `Motor2`
   - Previous conveyor: Conveyor 1
   - Next conveyor: Conveyor 3
   - Stop sensor: StopSensor2 (mapped to %I0.1)
   - Motor output: HW_Motor2_Run (mapped to %Q0.1)

3. **Conveyor 3** (Exit conveyor)
   - Name: `Conveyor_3`
   - Motor: `Motor3`
   - Previous conveyor: Conveyor 2
   - Next conveyor: None (exit point)
   - Stop sensor: StopSensor3 (mapped to %I0.2)
   - Motor output: HW_Motor3_Run (mapped to %Q0.2)

### Key Features

- **Material Flow Control**: Automatic coordination between adjacent conveyors using ReadyToReceive and ReadyToDeliver states
- **Stop Position Monitoring**: Each conveyor has a stop sensor to detect material presence
- **Motor Control**: Full motor control with ramp-up/ramp-down functionality
- **I/O Integration**: Physical I/O mapping for sensors and motor outputs
- **Operating Modes**: Support for Manual, Automatic, and Commissioning modes via global operating mode manager
- **Release Signal**: Global release signal for enabling/disabling all conveyors (e.g., safety interlocks, emergency stop)
- **Off-delay handling**: Each conveyor uses a 5 second off-delay in the current configuration

## Implementation Details

### Files Modified

1. **[`src/Configuration.st`](src/Configuration.st:1)** - Global variable declarations with initializers
   - Three `ConveyorBase` instances configured with initializers
   - Three `MotorGeneric` instances configured with initializers
   - Three `BinSignal` stop sensors
   - Global `OperatingModeManager` shared by all conveyors
   - Global `SimpleRelease` shared by all conveyors
   - Physical I/O mappings (AT %I and AT %Q)
   
   **Key advantage**: All configuration is done declaratively in the VAR_GLOBAL section using initializers, making the code cleaner and more maintainable.

2. **[`src/MainProgram.st`](src/MainProgram.st:1)** - Main program logic
    - No explicit initialization needed; `RunCyclic()` handles initialization internally
   - **Cyclic execution** with four key steps:
       1. Update the simulation state when enabled
       2. Execute conveyor logic for Conveyor1, Conveyor2, and Conveyor3
       3. Execute the shared reset manager
       4. Update cycle time statistics

3. **[`src/SimpleRelease.st`](src/SimpleRelease.st:1)** - Simple release implementation
   - Implements the release interface used by the conveyor components
   - Provides a boolean signal to enable/disable conveyor operation
   - Can be used for safety interlocks, emergency stop, or manual enable/disable

### Motor Control

Each conveyor has a `MotorGeneric` instance that provides:

- **Ramp Control**: Smooth acceleration and deceleration based on configured rates
- **Speed Control**: Maintains target speed with tolerance checking
- **State Feedback**: `IsRunning()`, `IsAtSpeed()`, `GetCurrentSpeed()`

The motors are associated with the three configured conveyors in [`src/Configuration.st`](src/Configuration.st:1).

The main program executes the conveyor logic cyclically in [`src/MainProgram.st`](src/MainProgram.st:1):
```st
Conveyor1.RunCyclic();
Conveyor2.RunCyclic();
Conveyor3.RunCyclic();
```

### I/O Handling

#### Input Sensors
The stop sensors are mapped to `%I0.0` through `%I0.2` in [`src/Configuration.st`](src/Configuration.st:1). In the current example, the simulation can overwrite the hardware inputs during cyclic execution.

#### Output Mapping
Motor run signals are written to physical outputs:
```st
HW_Motor1_Run := Motor1.IsRunning();
HW_Motor2_Run := Motor2.IsRunning();
HW_Motor3_Run := Motor3.IsRunning();
```

### I/O Address Configuration

Current I/O mapping in [`Configuration.st`](src/Configuration.st:1):

| Signal | Address | Description |
|--------|---------|-------------|
| HW_StopSensor1 | %I0.0 | Stop sensor for Conveyor 1 |
| HW_StopSensor2 | %I0.1 | Stop sensor for Conveyor 2 |
| HW_StopSensor3 | %I0.2 | Stop sensor for Conveyor 3 |
| HW_Motor1_Run | %Q0.0 | Motor run signal for Conveyor 1 |
| HW_Motor2_Run | %Q0.1 | Motor run signal for Conveyor 2 |
| HW_Motor3_Run | %Q0.2 | Motor run signal for Conveyor 3 |
| HW_ResetButton | %I0.3 | Reset button input |

**⚠️ Important**: Adjust these addresses to match your actual PLC hardware configuration!

### Conveyor Coordination

The conveyors automatically coordinate material transfer through the following states:

- **ReadyToReceive**: Conveyor signals to upstream conveyor that it can accept material
- **ReadyToDeliver**: Conveyor signals to downstream conveyor that it has material ready
- **TransferInProgress**: Active material transfer to next conveyor

The coordination logic ensures:
- Material doesn't transfer until downstream conveyor is ready
- Motors run with appropriate timing and off-delays
- Smooth material flow through the entire line

## Cyclic Execution Flow

The [`MainProgram`](src/MainProgram.st:1) executes these steps every PLC cycle:

```
┌─────────────────────────────────────────┐
│ 1. Read Physical Inputs                 │
│    ConveyorSim.Update()                 │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│ 2. Execute Conveyor Logic               │
│    Conveyor1/2/3.RunCyclic()            │
│    - Evaluates states                   │
│    - Decides motor on/off               │
│    - Coordinates with neighbors         │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│ 3. Execute Reset Manager                │
│    GlobalResetManager.RunCyclic()       │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│ 4. Update Cycle Time Statistics         │
│    _cycleTimeMeasurement.StopCycle()    │
└─────────────────────────────────────────┘
```

## Dependencies

- **@simatic-ax/conveyor**: Provides `ConveyorBase` and `MotorGeneric`
- **@simatic-ax/automationframework**: Equipment base classes and operating mode management
- **@simatic-ax/io**: Input/output signal handling (`BinSignal`)
- **@ax/simatic-clocks**: System time functions for motor timing

## Operating Mode Control

The conveyor line uses a global `OperatingModeManager` that controls all conveyors simultaneously. Three operating modes are available:

- **Manual**: Conveyors are controlled in manual mode
- **Automatic**: Conveyors start automatically based on material flow coordination
- **Commissioning**: Special mode for testing and commissioning

### Changing Operating Mode

To change the operating mode, use the `SetOperatingMode()` method:

```st
// Switch to Automatic mode
GlobalOpMode.SetOperatingMode(mode := OperatingModes#Automatic);

// Switch to Manual mode
GlobalOpMode.SetOperatingMode(mode := OperatingModes#Manual);
```

## Release Signal Control

The global [`SimpleRelease`](src/SimpleRelease.st:1) signal controls whether all conveyors are allowed to operate. This can be used for:

- Emergency stop functionality
- Safety interlocks
- Manual enable/disable of the entire line
- Upstream system dependencies

### Controlling the Release Signal

```st
// Enable all conveyors
GlobalRelease.Signal := TRUE;

// Disable all conveyors (emergency stop)
GlobalRelease.Signal := FALSE;
```

When the release signal is FALSE, all conveyors will stop immediately regardless of operating mode.

## Next Steps

To complete the deployment:

1. **Adjust I/O Addresses**: Update the AT %I and AT %Q addresses in [`Configuration.st`](src/Configuration.st:1) to match your PLC hardware
2. **Connect Operating Mode Control**: Link [`GlobalOpMode`](src/Configuration.st:1) to HMI or physical selector switch
3. **Connect Release Signal**: Link [`GlobalRelease.Signal`](src/Configuration.st:1) to emergency stop circuit and safety system
4. **Add HMI Interface**: Create operator interface for monitoring and control
5. **Tune Parameters**: Adjust simulation timing and off-delay times based on your application

## Building and Deployment

Build the project:
```bash
apax build
```

Download to PLC:
```bash
apax dlplc
```

Make sure to update the IP address in [`apax.yml`](apax.yml:39) to match your target PLC.

## Troubleshooting

- **Motors not running**:
  - Check that [`GlobalRelease.Signal`](src/Configuration.st:1) is TRUE
   - Verify operating mode is set correctly
   - In Automatic mode, ensure conveyors have completed their normal startup sequence
- **No sensor response**: Verify I/O addresses match your hardware configuration
- **Jerky motion**: Adjust simulation timing and conveyor parameters in the configuration
- **Material flow issues**: Check conveyor linking (PrevConveyor/NextConveyor) and sensor placement
- **All conveyors stopped**: Check [`GlobalRelease.Signal`](src/Configuration.st:1) - may be FALSE due to safety interlock or emergency stop
