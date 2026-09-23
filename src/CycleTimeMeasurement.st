USING Siemens.Simatic.Clocks;
USING System.Timer;

NAMESPACE Simatic.Ax.Measurement
    /// Class for measuring and averaging PLC cycle time over a configurable period
    CLASS CycleTimeMeasurement
        VAR CONSTANT
            DEFAULT_AVERAGING_PERIOD : TIME := T#1s; // Default 1 second averaging
        END_VAR
        
        VAR PUBLIC
            /// Current cycle time in milliseconds
            CycleTimeMs : LREAL := 0.0;
            
            /// Average cycle time over the averaging period (in milliseconds)
            AverageMs : LREAL := 0.0;
            
            /// Minimum cycle time in the current averaging period (in milliseconds)
            MinMs : LREAL := 999999.0;
            
            /// Maximum cycle time in the current averaging period (in milliseconds)
            MaxMs : LREAL := 0.0;
            
            /// Current cycle time in seconds
            CycleTimeSec : LREAL := 0.0;
            
            /// Number of cycles in current averaging period
            CycleCount : INT := 0;
        END_VAR
        
        VAR PRIVATE
            // Runtime measurement instance
            _runtimeMeasurement : RuntimeMeasurement;
            
            // Cycle time data
            _cycleTime : LTIME;
            _cycleTimeNs : LINT;
            
            // Average calculation
            _cycleTimeSum : LREAL := 0.0;
            _averageTimer : OnDelay;
            _averagingPeriod : TIME := DEFAULT_AVERAGING_PERIOD;
            
            // Initialization flag
            _initialized : BOOL := FALSE;
        END_VAR
        
        /// Initialize the measurement with optional custom averaging period
        METHOD PUBLIC Initialize
            VAR_INPUT
                averagingPeriod : TIME := T#1s; // Averaging period (default 1 second)
            END_VAR
            
            _averagingPeriod := averagingPeriod;
            THIS.Reset();
            _initialized := TRUE;
        END_METHOD
        
        /// Start measurement at the beginning of the cycle
        METHOD PUBLIC StartCycle
            IF NOT _initialized THEN
                THIS.Initialize();
            END_IF;
            
            _runtimeMeasurement.Start();
        END_METHOD
        
        /// Stop measurement at the end of the cycle and calculate statistics
        METHOD PUBLIC StopCycle
            // Stop runtime measurement and get cycle time
            _cycleTime := _runtimeMeasurement.Stop();
            
            // Get elapsed time in different formats
            _cycleTimeNs := _runtimeMeasurement.GetElapsedNanoseconds();
            CycleTimeSec := _runtimeMeasurement.GetElapsedSeconds();
            
            // Convert nanoseconds to milliseconds for easier reading
            CycleTimeMs := TO_LREAL(_cycleTimeNs) / 1000000.0;
            
            // Calculate average over the configured period
            _cycleTimeSum := _cycleTimeSum + CycleTimeMs;
            CycleCount := CycleCount + 1;
            
            // Track min/max
            IF CycleTimeMs < MinMs THEN
                MinMs := CycleTimeMs;
            END_IF;
            IF CycleTimeMs > MaxMs THEN
                MaxMs := CycleTimeMs;
            END_IF;
            
            // Check if averaging period has elapsed
            _averageTimer(signal := TRUE, duration := _averagingPeriod);
            
            IF _averageTimer.output THEN
                // Calculate average
                IF CycleCount > 0 THEN
                    AverageMs := _cycleTimeSum / TO_LREAL(CycleCount);
                END_IF;
                
                // Reset for next averaging period
                _cycleTimeSum := 0.0;
                CycleCount := 0;
                MinMs := 999999.0;
                MaxMs := 0.0;
                _averageTimer(signal := FALSE, duration := _averagingPeriod);
            END_IF;
        END_METHOD
        
        /// Reset all measurements
        METHOD PUBLIC Reset
            _cycleTimeSum := 0.0;
            CycleCount := 0;
            MinMs := 999999.0;
            MaxMs := 0.0;
            CycleTimeMs := 0.0;
            AverageMs := 0.0;
            CycleTimeSec := 0.0;
            _averageTimer(signal := FALSE, duration := _averagingPeriod);
        END_METHOD
        
        /// Get the current cycle time in nanoseconds
        METHOD PUBLIC GetCycleTimeNs : LINT
            GetCycleTimeNs := _cycleTimeNs;
        END_METHOD
        
        /// Get the raw LTIME value
        METHOD PUBLIC GetCycleTime : LTIME
            GetCycleTime := _cycleTime;
        END_METHOD
        
    END_CLASS
END_NAMESPACE
