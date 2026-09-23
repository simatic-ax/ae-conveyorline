# Conveyor Line System - Simple Example (3 Conveyors)

## Description

This SIMATIC AX application example demonstrates a simple conveyor system with **3 conveyors in series**.

### **MainProgram - 3 Conveyors in 1 Line**
- **Line 1**: Conveyors 1-3 (sequential operation)
- Simple material handling demonstration
- Perfect for learning and testing

The system implements complete material handling with:
- **Automatic stop position control** - Items stop at designated positions
- **Motor control** - Each conveyor has its own motor with acceleration/deceleration
- **Sensor simulation** - Shift register-based simulation for testing without hardware
- **Performance monitoring** - Real-time cycle time measurement and averaging
- **Operating modes** - Manual and Automatic operation modes

## 🎯 Key Features

### 1. **Simple 3-Conveyor Line**

- 3 conveyors in series (Conveyor1 → Conveyor2 → Conveyor3)
- Sequential material flow
- Shared global control (OperatingMode, Release, Reset)
- Minimal configuration for easy understanding

### 2. **Shift Register Simulation**

- 1 shift register for the entire conveyor line
- 30-position shift register (3 seconds @ 100ms intervals)
- Configurable package generation (default: every 2 seconds)
- Packages move through all 3 conveyors sequentially
- Sensor positions: Position 0 (start), Position 10 (after 1.0s), Position 20 (after 2.0s)

### 3. **Cycle Time Measurement**

The program includes encapsulated `CycleTimeMeasurement`:

**Where to read cycle times:**

- `MainProgram.CurrentCycleTimeMs` - Current PLC cycle time in milliseconds
- `MainProgram.AverageCycleTimeMs` - Average cycle time over 1 second
- `MainProgram._cycleTimeMeasurement.MinMs` - Minimum cycle time
- `MainProgram._cycleTimeMeasurement.MaxMs` - Maximum cycle time
- `MainProgram._cycleTimeMeasurement.CycleCount` - Number of cycles measured

### 4. **Watchlist File**

- `watchlist/default.mon` - System overview with all 3 conveyors

## 🚀 Getting Started

### Prerequisites

- **SIMATIC AX** development environment (version 2510.0.0 or higher)
- **AX Code** (VS Code extension)
- **APAX** package manager
- **PLC**: Siemens S7-1500 or PLCSIM Advanced
- **Git** (for cloning the repository)

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/simatic-ax/ae-conveyorline.git
   cd ae-conveyorline
   ```

2. **Install dependencies**:

   ```bash
   apax install
   ```

3. **Open in AX Code** (VS Code with SIMATIC AX extension):

   ```bash
   code .
   ```
   
   Or use the SIMATIC AX specific command:
   ```bash
   axcode .
   ```

## 🔧 Configuration

### PLC Connection

Edit `apax.yml` to configure your PLC IP address:

```yml
variables:
  IP_ADDRESS: "192.168.0.1"  # Change this to your PLC's IP address

scripts:
  dlplc:
    - apax build
    - apax load
  load: apax sld load --input $BIN_FOLDER --target $IP_ADDRESS --restart --accept-security-disclaimer --log debug
```

Change `192.168.0.1` in the `IP_ADDRESS` variable to your PLC's IP address.

### I/O Mapping

**Inputs (Sensors)**:
- `%I0.0` - Sensor 1
- `%I0.1` - Sensor 2
- `%I0.2` - Sensor 3
- `%I0.3` - Reset Button

**Outputs (Motors)**:
- `%Q0.0` - Motor 1
- `%Q0.1` - Motor 2
- `%Q0.2` - Motor 3

## 📖 Usage

### Building the Project

```bash
apax build
```

### Deploying to PLC

**Using the apax dlplc script** (recommended):

```bash
apax dlplc
```

This will:
1. Build the project
2. Connect to the PLC at the configured IP address
3. Download the application
4. Start the PLC

**Manual deployment**:

```bash
apax sld load --input ./bin/1500 --target 192.168.0.1 --restart --accept-security-disclaimer --log debug
```

Or use the configured script:
```bash
apax load
```

### Using the Simulation

1. **Enable Simulation**:
   - Set `ConveyorSim.SimulationEnabled` to `TRUE` in the PLC

2. **Simulation Behavior**:
   - Packages are generated every 2 seconds at the start of the line
   - Packages move through the shift register at 100ms intervals
   - Sensors trigger when packages reach their positions (with 500ms detection window)
   - Package flow: Conveyor1 → Conveyor2 → Conveyor3
   - Sensor positions: Sensor1 at position 0, Sensor2 at position 10, Sensor3 at position 20

3. **Disable Simulation**:
   - Set simulation to `FALSE`
   - All sensor signals reset to `FALSE`
   - System ready for real hardware sensors

### Operating Modes

**Manual Mode**:
- Set `ManualMode` to `TRUE`
- Conveyors can be controlled individually
- Useful for maintenance and testing

**Automatic Mode**:
- Set `ManualMode` to `FALSE`
- Conveyors operate automatically based on sensor inputs
- Normal production operation

### Monitoring Cycle Times

**⏱️ Cycle Time Measurement in Watchlist:**

1. **Load the watchlist**:
   - `watchlist/default.mon` - Contains all cycle time variables

2. **Monitor cycle time variables**:
   - `CurrentCycleTimeMs` - Real-time cycle time
   - `AverageCycleTimeMs` - 1-second average
   - `_cycleTimeMeasurement.MinMs` - Minimum recorded
   - `_cycleTimeMeasurement.MaxMs` - Maximum recorded
   - `_cycleTimeMeasurement.CycleCount` - Total cycles

**Typical Values:**
- Current: 0.3 - 1.0 ms (depends on system load)
- Average: 0.5 - 0.8 ms (stable operation)
- Min: 0.2 - 0.5 ms
- Max: 0.8 - 1.5 ms (includes occasional peaks)

### Monitoring Conveyors

**Key Variables:**
- `HW_StopSensor1` - Sensor 1 input state
- `HW_StopSensor2` - Sensor 2 input state
- `HW_StopSensor3` - Sensor 3 input state
- `HW_Motor1_Run` - Motor 1 output status
- `HW_Motor2_Run` - Motor 2 output status
- `HW_Motor3_Run` - Motor 3 output status
- `ConveyorSim.SimulationEnabled` - Simulation on/off
- `Conveyor1._stopPosition._itemInStopPosition` - Item at stop position 1
- `Conveyor2._stopPosition._itemInStopPosition` - Item at stop position 2
- `Conveyor3._stopPosition._itemInStopPosition` - Item at stop position 3

## 📁 Project Structure

```
ae-conveyorline/
├── src/
│   ├── Configuration.st              # System configuration (3 conveyors)
│   ├── MainProgram.st                # Main cyclic program (3 conveyors)
│   ├── ConveyorSimulation.st         # Simulation (3 conveyors)
│   ├── CycleTimeMeasurement.st       # Performance monitoring class
│   └── SimpleRelease.st              # Release signal implementation
├── watchlist/
│   └── default.mon                   # System overview (3 conveyors)
├── docs/
│   └── Simulation.md                 # Simulation documentation
├── apax.yml                          # Project configuration with dlplc script
└── README.md                         # This file
```

## 🔍 Key Classes and Components

### ConveyorBase
- From `@simatic-ax/conveyor` package
- Manages conveyor logic and stop positions
- Handles motor control and sensor inputs

### MotorGeneric
- Controls motor with acceleration/deceleration
- Implements motor control interfaces

### ConveyorSimulation
- Custom simulation class
- Shift register-based package movement
- Configurable timing and sensor positions

### CycleTimeMeasurement
- Encapsulated performance monitoring
- Uses `RuntimeMeasurement` from `@ax/simatic-clocks`
- Provides current, average, min, max cycle times
- Configurable averaging period (default 1 second)

## 🛠️ Customization

### Changing Conveyor Speed

Edit Configuration.st:

```st
Motor1 : MotorGeneric := (
    MotorOutput := MotorOutput1,
    ExternalRelease := GlobalRelease
    // Note: Speed parameters are managed by MotorGeneric class
    // Refer to @simatic-ax/motor documentation for speed configuration
);
```

**Note**: The current configuration uses default motor parameters. To customize speed, acceleration, and deceleration, refer to the `@simatic-ax/motor` package documentation.

### Adjusting Simulation Timing

Edit ConveyorSimulation.st:

```st
VAR CONSTANT
    SHIFT_INTERVAL : TIME := T#50ms;  // Change from 100ms to 50ms
    PACKAGE_INTERVAL_POSITIONS : INT := 40;  // Change package frequency
    REGISTER_SIZE : INT := 60;  // Double the register size
END_VAR
```

**Note**: When changing `REGISTER_SIZE`, you must also update the array declaration:
```st
_shiftRegister : ARRAY[0..59] OF BOOL;  // Adjust upper bound to REGISTER_SIZE - 1
```

### Adjusting Sensor Positions

Edit ConveyorSimulation.st:

```st
// Sensor position mapping (in shift register positions)
_sensor1Position : INT := 0;   // Position 0 (start)
_sensor2Position : INT := 10;  // Position 10 (after 1.0s)
_sensor3Position : INT := 20;  // Position 20 (after 2.0s)
```

### Adjusting Sensor Detection Window

Edit ConveyorSimulation.st:

```st
_sensorWindow : INT := 5; // 5 positions = 500ms (default)
// Change to 3 for 300ms detection window
// Change to 10 for 1000ms detection window
```

## 📊 Performance

- **Memory Usage**: Minimal (depends on PLC model)
- **Typical Cycle Time**: 0.3 - 1.0 ms (measured via CycleTimeMeasurement)
- **Average Cycle Time**: 0.5 - 0.8 ms (stable operation)
- **Download Time**: ~3-4 seconds
- **Supported PLC**: S7-1500 series, PLCSIM Advanced

## 🐛 Troubleshooting

### Motors Not Running
- Check `GlobalRelease.Signal` is `TRUE`
- Verify operating mode is set correctly
- Check sensor simulation is enabled if using simulation

### Sensors Not Triggering
- Enable simulation: `ConveyorSim.SimulationEnabled := TRUE`
- Check shift register is running (monitor `_packageCounter` variable)
- Verify I/O mapping matches your hardware

### Build Errors
- Run `apax install` to ensure all dependencies are installed
- Check SIMATIC AX version compatibility
- Verify all USING statements are correct

### Download Errors
- Verify PLC IP address in `apax.yml`
- Check PLC is reachable: `ping 192.168.0.1`
- Ensure PLC is in STOP mode before download
- Check firewall settings

## 📚 Additional Documentation

### Project Documentation
- [Simulation Documentation (German)](docs/Simulation.md) - Detailed shift register simulation explanation
- [Application Documentation](docs/app.md) - Application overview
- [Conveyor Line Documentation](docs/ConveyorLine.md) - Conveyor system details

### External Resources
- [SIMATIC AX Conveyor Package](https://github.com/simatic-ax/conveyor)
- [SIMATIC AX Documentation](https://console.simatic-ax.siemens.io)
- [APAX Package Manager](https://console.simatic-ax.siemens.io/docs/apax)

## 🤝 Contribution

Contributions are welcome! Please:
1. Report bugs in the Issues section
2. Propose changes via Pull Requests
3. Follow the existing code style
4. Add tests for new features

## 📄 License

Please read the [Legal information](LICENSE.md)

---

**Project Status**: ✅ Active Development

**Last Updated**: 2026-07-21

**SIMATIC AX Version**: Compatible with @ax/simatic-ax ^2510.0.0

**Configuration**: 3 Conveyors in Series (Simple Example)

**Dependencies**:
- `@simatic-ax/conveyor`: 1.0.0
- `@simatic-ax/snippetscollection`: 1.1.0
- `@ax/sdk`: 2510.20.0 (devDependency)
