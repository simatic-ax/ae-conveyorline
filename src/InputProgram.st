USING Simatic.Ax.IO.Input;
USING Simatic.Ax.Simulation;

PROGRAM HardwareInputs
    VAR_EXTERNAL
        // Reset button for all conveyors (BinSignal)
        ResetButton : BinSignal;

        // Stop sensors (3 Conveyors)
        StopSensor1 : BinSignal;
        StopSensor2 : BinSignal;
        StopSensor3 : BinSignal;

        // Conveyor simulation
        ConveyorSim : ConveyorSimulation;

        // Physical I/O (3 Conveyors)
        HW_StopSensor1 : BOOL;
        HW_StopSensor2 : BOOL;
        HW_StopSensor3 : BOOL;

        // Physical I/O for Reset Button
        HW_ResetButton : BOOL;
    END_VAR

    VAR
        EffectiveStopSensor1 : BOOL := FALSE;
        EffectiveStopSensor2 : BOOL := FALSE;
        EffectiveStopSensor3 : BOOL := FALSE;
    END_VAR

    // Read reset button input
    ResetButton.ReadCyclic(signal := HW_ResetButton);

    // If simulation is enabled, use simulated sensor values
    // If simulation is disabled, reset all sensor signals to FALSE
    IF ConveyorSim.SimulationEnabled THEN
        EffectiveStopSensor1 := ConveyorSim.Sensor1;
        EffectiveStopSensor2 := ConveyorSim.Sensor2;
        EffectiveStopSensor3 := ConveyorSim.Sensor3;
    ELSE
        EffectiveStopSensor1 := HW_StopSensor1;
        EffectiveStopSensor2 := HW_StopSensor2;
        EffectiveStopSensor3 := HW_StopSensor3;
    END_IF;

    // Read physical inputs and update BinSignals (3 Conveyors)
    StopSensor1.ReadCyclic(signal := EffectiveStopSensor1);
    StopSensor2.ReadCyclic(signal := EffectiveStopSensor2);
    StopSensor3.ReadCyclic(signal := EffectiveStopSensor3);
END_PROGRAM