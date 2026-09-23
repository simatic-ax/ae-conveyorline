USING Simatic.Ax.Conveyor;
USING Simatic.Ax.Motor;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.Simulation;
USING Simatic.Ax.Measurement;
USING System.Timer;

PROGRAM MainProgram
    VAR_EXTERNAL

        // Manual Mode
        ManualMode : BOOL;

        // Conveyor line (3 Conveyors)
        Conveyor1 : ConveyorBase;
        Conveyor2 : ConveyorBase;
        Conveyor3 : ConveyorBase;
        
        // Global operating mode manager (shared by all conveyors)
        GlobalOpMode : OperatingModeManager;
        
        // Global reset command manager (shared by all conveyors)
        GlobalResetManager : ResetCommandManager;
        
        // Global release signal (shared by all conveyors)
        GlobalRelease : SimpleRelease;
        
        // Conveyor simulation
        ConveyorSim : ConveyorSimulation;
        
    END_VAR
    
    VAR
        // Cycle time measurement (encapsulated)
        _cycleTimeMeasurement : CycleTimeMeasurement;
        
        // Current and average cycle time values
        CurrentCycleTimeMs : LREAL := 0.0;
        AverageCycleTimeMs : LREAL := 0.0;
    END_VAR
    
    VAR_TEMP
    END_VAR
    
    
    // Start cycle time measurement
    _cycleTimeMeasurement.StartCycle();
    
    // Handle operating mode
    IF ManualMode THEN
        GlobalOpMode.SetOperatingMode(mode := OperatingModes#Manual);
    ELSE
        GlobalOpMode.SetOperatingMode(mode := OperatingModes#Automatic);
    END_IF;


    // ========================================
    // CYCLIC EXECUTION - Called every PLC cycle
    // ========================================

    // 0. Update simulation (if enabled, overwrites HW inputs)
    ConveyorSim.Update();

    // 1. Execute conveyor logic (3 Conveyors)
    Conveyor1.RunCyclic();
    Conveyor2.RunCyclic();
    Conveyor3.RunCyclic();

    // 2. Execute reset manager cyclic (MUST be called after all equipment)
    GlobalResetManager.RunCyclic();
    
    // Stop cycle time measurement and calculate statistics
    _cycleTimeMeasurement.StopCycle();
    
    // Assign values to local variables
    CurrentCycleTimeMs := _cycleTimeMeasurement.CycleTimeMs;
    AverageCycleTimeMs := _cycleTimeMeasurement.AverageMs;
    
END_PROGRAM
