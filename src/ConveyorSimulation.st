USING System.Timer;

NAMESPACE Simatic.Ax.Simulation
    /// Simulation class for conveyor sensor signals using shift register approach
    /// Simulates packages moving along 1 conveyor line (3 conveyors total)
    CLASS ConveyorSimulation
        VAR CONSTANT
            CONVEYOR_LENGTH : LREAL := 2.0; // Conveyor length in meters
            CONVEYOR_SPEED : LREAL := 1.5;  // Conveyor speed in m/s
            SHIFT_INTERVAL : TIME := T#100ms; // Time interval for shift register update
            REGISTER_SIZE : INT := 30; // Size of shift register (3 seconds / 100ms = 30 positions)
            PACKAGE_INTERVAL_POSITIONS : INT := 20; // Positions between packages (2s / 100ms = 20)
        END_VAR
        
        VAR PUBLIC
            /// Enable/disable simulation
            SimulationEnabled : BOOL := FALSE;
            
            /// Simulated sensor outputs (3 Conveyors)
            Sensor1 : BOOL := FALSE;
            Sensor2 : BOOL := FALSE;
            Sensor3 : BOOL := FALSE;
        END_VAR
        
        VAR PRIVATE
            // Shift register for the conveyor line
            _shiftRegister : ARRAY[0..29] OF BOOL;
            
            // Timer for shift register update
            _shiftTimer : OnDelay;
            _shiftTimerReset : BOOL := FALSE;
            
            // Package generation counter
            _packageCounter : INT := 0;
            
            // Sensor position mapping (in shift register positions)
            _sensor1Position : INT := 0;   // Position 0 (start)
            _sensor2Position : INT := 10;  // Position 10 (after 1.0s)
            _sensor3Position : INT := 20;  // Position 20 (after 2.0s)
            
            // Sensor trigger window
            _sensorWindow : INT := 5; // 5 positions = 500ms
            
            // Initialization flag
            _initialized : BOOL := FALSE;
        END_VAR
        
        /// Initialize simulation
        METHOD PUBLIC Initialize
            VAR_TEMP
                i : INT;
            END_VAR
            
            // Clear shift register
            FOR i := 0 TO (REGISTER_SIZE - 1) DO
                _shiftRegister[i] := FALSE;
            END_FOR;
            
            _packageCounter := 0;
            _initialized := TRUE;
        END_METHOD
        
        /// Cyclic update method - must be called every PLC cycle
        METHOD PUBLIC Update
            VAR_TEMP
                i : INT;
            END_VAR
            
            // If simulation is disabled, reset all sensors
            IF NOT SimulationEnabled THEN
                IF _initialized THEN
                    THIS.Initialize();
                    _initialized := FALSE;
                END_IF;
                THIS.ResetAllSensors();
                RETURN;
            END_IF;
            
            // Initialize on first run
            IF NOT _initialized THEN
                THIS.Initialize();
            END_IF;
            
            // Update shift register at defined interval
            _shiftTimer(signal := NOT _shiftTimerReset, duration := SHIFT_INTERVAL);
            
            IF _shiftTimer.output THEN
                // Shift all positions one step forward
                FOR i := (REGISTER_SIZE - 1) TO 1 BY -1 DO
                    _shiftRegister[i] := _shiftRegister[i - 1];
                END_FOR;
                
                // Generate new packages
                _packageCounter := _packageCounter + 1;
                IF _packageCounter >= PACKAGE_INTERVAL_POSITIONS THEN
                    _shiftRegister[0] := TRUE;
                    _packageCounter := 0;
                ELSE
                    _shiftRegister[0] := FALSE;
                END_IF;
                
                // Reset timer for next cycle
                _shiftTimerReset := TRUE;
            ELSE
                _shiftTimerReset := FALSE;
            END_IF;
            
            // Update sensor outputs (3 Conveyors)
            Sensor1 := THIS.CheckSensorWindow(_sensor1Position);
            Sensor2 := THIS.CheckSensorWindow(_sensor2Position);
            Sensor3 := THIS.CheckSensorWindow(_sensor3Position);
        END_METHOD
        
        /// Reset all sensor outputs
        METHOD PRIVATE ResetAllSensors
            Sensor1 := FALSE;
            Sensor2 := FALSE;
            Sensor3 := FALSE;
        END_METHOD
        
        /// Check if any position within sensor window contains a package
        METHOD PRIVATE CheckSensorWindow : BOOL
            VAR_INPUT
                centerPosition : INT;
            END_VAR
            VAR_TEMP
                i : INT;
                startPos : INT;
                endPos : INT;
                packageDetected : BOOL := FALSE;
            END_VAR
            
            // Calculate window range
            startPos := centerPosition;
            endPos := centerPosition + _sensorWindow - 1;
            
            // Check if any position in window has a package
            FOR i := startPos TO endPos DO
                IF i >= 0 AND i < REGISTER_SIZE THEN
                    IF _shiftRegister[i] THEN
                        packageDetected := TRUE;
                    END_IF;
                END_IF;
            END_FOR;
            
            CheckSensorWindow := packageDetected;
        END_METHOD
        
        /// Get shift register state for debugging (returns position value)
        METHOD PUBLIC GetRegisterState : BOOL
            VAR_INPUT
                position : INT;
            END_VAR
            
            IF position >= 0 AND position < REGISTER_SIZE THEN
                GetRegisterState := _shiftRegister[position];
            ELSE
                GetRegisterState := FALSE;
            END_IF;
        END_METHOD
        
    END_CLASS
END_NAMESPACE
