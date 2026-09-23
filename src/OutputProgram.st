USING Simatic.Ax.IO.Output;

PROGRAM HardwareOutputs
    VAR_EXTERNAL
        // Motor outputs (3 Conveyors)
        MotorOutput1 : BinOutput;
        MotorOutput2 : BinOutput;
        MotorOutput3 : BinOutput;

        // Physical I/O - Motors (3 Conveyors)
        HW_Motor1_Run : BOOL;
        HW_Motor2_Run : BOOL;
        HW_Motor3_Run : BOOL;
    END_VAR

    // Write motor states to physical outputs (3 Conveyors)
    MotorOutput1.WriteCyclic(Q => HW_Motor1_Run);
    MotorOutput2.WriteCyclic(Q => HW_Motor2_Run);
    MotorOutput3.WriteCyclic(Q => HW_Motor3_Run);
END_PROGRAM