USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor

    /// Simple release implementation that can be controlled by a boolean signal
    /// Used to enable/disable equipment operation (e.g., safety interlocks, enable signals)
    CLASS SimpleRelease IMPLEMENTS IRelease
        VAR PUBLIC
            /// Release signal - TRUE allows operation, FALSE prevents operation
            Signal : BOOL := TRUE;
        END_VAR
        
        /// Returns TRUE when equipment is released and allowed to operate
        METHOD PUBLIC IsReleased : BOOL
            IsReleased := Signal;
        END_METHOD
    END_CLASS

END_NAMESPACE
