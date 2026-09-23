USING Simatic.Ax.Conveyor;
USING Simatic.Ax.IO.Input;
USING Simatic.Ax.IO.Output;
USING Simatic.Ax.Motor;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.Simulation;

CONFIGURATION MyConfiguration
    TASK Main (PRIORITY := 1);
    PROGRAM P0 WITH Main : HardwareInputs;
    PROGRAM P1 WITH Main : MainProgram;
    PROGRAM P2 WITH Main : HardwareOutputs;
    VAR_GLOBAL
        // Manual Mode
        ManualMode : BOOL := FALSE;
        
        // Reset button for all conveyors (BinSignal from @simatic-ax/io)
        ResetButton : BinSignal;
        
        // Conveyor simulation for sensor signals
        ConveyorSim : ConveyorSimulation;
        
        // Global operating mode manager (shared by all conveyors)
        GlobalOpMode : OperatingModeManager;
        
        // Global reset command manager (shared by all conveyors)
        GlobalResetManager : ResetCommandManager := (ResetSignal := ResetButton);
        
        // Global release signal (shared by all conveyors)
        GlobalRelease : SimpleRelease := (Signal := TRUE);
        
        // Motor outputs using BinOutput (3 Conveyors)
        MotorOutput1 : BinOutput;
        MotorOutput2 : BinOutput;
        MotorOutput3 : BinOutput;
        
        // Motors for each conveyor (3 Conveyors)
        Motor1 : MotorGeneric := (MotorOutput := MotorOutput1, ExternalRelease := GlobalRelease);
        Motor2 : MotorGeneric := (MotorOutput := MotorOutput2, ExternalRelease := GlobalRelease);
        Motor3 : MotorGeneric := (MotorOutput := MotorOutput3, ExternalRelease := GlobalRelease);
        
        // Stop sensors (3 Conveyors)
        StopSensor1 : BinSignal;
        StopSensor2 : BinSignal;
        StopSensor3 : BinSignal;
        
        // Conveyor line (3 Conveyors in series)
        Conveyor1 : ConveyorBase := (
            Name := 'Conveyor_1',
            StopSensor := StopSensor1,
            Motor := Motor1,
            NextConveyor := Conveyor2,
            PrevConveyor := NULL,
            OffDelayTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease,
            ResetCommand := GlobalResetManager);

        Conveyor2 : ConveyorBase := (
            Name := 'Conveyor_2',
            StopSensor := StopSensor2,
            Motor := Motor2,
            NextConveyor := Conveyor3,
            PrevConveyor := Conveyor1,
            OffDelayTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease,
            ResetCommand := GlobalResetManager);

        Conveyor3 : ConveyorBase := (
            Name := 'Conveyor_3',
            StopSensor := StopSensor3,
            Motor := Motor3,
            NextConveyor := NULL,
            PrevConveyor := Conveyor2,
            OffDelayTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease,
            ResetCommand := GlobalResetManager);

        // Physical I/O mapping (3 Conveyors)
        HW_StopSensor1 AT %I0.0 : BOOL;
        HW_StopSensor2 AT %I0.1 : BOOL;
        HW_StopSensor3 AT %I0.2 : BOOL;
        // Motor outputs (3 Conveyors)
        HW_Motor1_Run AT %Q0.0 : BOOL;
        HW_Motor2_Run AT %Q0.1 : BOOL;
        HW_Motor3_Run AT %Q0.2 : BOOL;
        // Physical I/O for Reset Button
        HW_ResetButton AT %I0.3 : BOOL;
    END_VAR
END_CONFIGURATION
