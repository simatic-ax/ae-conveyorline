# NewLine Program - 32 Conveyor System

## Übersicht

Das NewLineProgram wurde erfolgreich mit **32 Förderbändern** implementiert, die miteinander verbunden sind und gemeinsam laufen. Das System enthält:

- **32 Förderbänder** (NewLine_Conveyor1 bis NewLine_Conveyor32)
- **32 Motoren** (NewLine_Motor1 bis NewLine_Motor32)
- **Lichtschranken-Simulation** für alle 32 Förderbänder
- **Zykluszeit-Messung** über alle 32 Förderbänder

## Implementierte Dateien

### 1. `src/NewLineSimulation.st`
Simulationsklasse für die Lichtschranken-Signale:
- Verwendet ein Shift-Register-Verfahren zur Simulation von Paketen
- Register-Größe: 230 Positionen (23 Sekunden bei 100ms Intervall)
- Paket-Intervall: 20 Positionen (2 Sekunden zwischen Paketen)
- Jedes Förderband hat eine eigene Sensor-Position (0,7s Abstand)
- Sensor-Fenster: 5 Positionen (500ms)

**Aktivierung der Simulation:**
```
NewLineSim.SimulationEnabled := TRUE;
```

### 2. `src/NewLineProgram.st`
Hauptprogramm mit 32 Förderbändern:
- **Betriebsarten**: Automatik und Manuell
- **Verkettung**: Jedes Förderband kommuniziert mit dem vorherigen und nächsten
  - Conveyor 1: Erstes Band (HasPrevConveyor = FALSE)
  - Conveyor 2-31: Mittlere Bänder (HasPrevConveyor = TRUE, HasNextConveyor = TRUE)
  - Conveyor 32: Letztes Band (HasNextConveyor = FALSE)
- **Zykluszeit-Messung**: Misst die Zykluszeit über alle 32 Förderbänder
  - `CurrentCycleTimeMs`: Aktuelle Zykluszeit in Millisekunden
  - `AverageCycleTimeMs`: Durchschnittliche Zykluszeit

### 3. `src/NewLineConfiguration.st`
Konfigurationsdatei mit globalen Variablen:
- Alle 32 Förderbänder als globale Variablen
- Alle 32 Motoren als globale Variablen
- Alle 32 Datenstrukturen (ConveyorData, MotorData)
- I/O-Mapping für 32 Sensoren (%I10.0 bis %I13.7)
- I/O-Mapping für 32 Motor-Ausgänge (%Q10.0 bis %Q13.7)

## Funktionsweise

### Lichtschranken-Simulation

Die Simulation verwendet ein Shift-Register, das alle 100ms aktualisiert wird:

1. **Paket-Generierung**: Alle 2 Sekunden wird ein neues Paket am Anfang des Shift-Registers erzeugt
2. **Paket-Transport**: Das Shift-Register verschiebt sich kontinuierlich vorwärts
3. **Sensor-Erkennung**: Jeder Sensor prüft ein Fenster von 5 Positionen
4. **Zeitverlauf**: 
   - Sensor 1: Position 0 (Start)
   - Sensor 2: Position 7 (nach 0,7s)
   - Sensor 3: Position 14 (nach 1,4s)
   - ...
   - Sensor 32: Position 217 (nach 21,7s)

### Förderband-Verkettung

Die Förderbänder sind in einer Kette verbunden:

```
[Conv1] → [Conv2] → [Conv3] → ... → [Conv31] → [Conv32]
```

Jedes Förderband:
- Empfängt Daten vom vorherigen Förderband (`PrevConveyorData`)
- Sendet Daten zum nächsten Förderband (`NextConveyorData`)
- Startet/stoppt basierend auf dem Status der benachbarten Förderbänder

### Zykluszeit-Messung

Die Zykluszeit wird für jeden PLC-Zyklus gemessen:
- **Start**: `_cycleTimeMeasurement.StartCycle()` am Anfang des Programms
- **Stop**: `_cycleTimeMeasurement.StopCycle()` am Ende des Programms
- **Ausgabe**: 
  - `CurrentCycleTimeMs`: Aktuelle Zykluszeit
  - `AverageCycleTimeMs`: Gleitender Durchschnitt

## Konfiguration

### Förderband-Parameter (für alle 32 Förderbänder identisch)

```
AutomaticSpeed: 1.5 m/s
ManualSpeed: 0.5 m/s
Acceleration: 1.0 m/s²
Deceleration: 1.0 m/s²
OffDelayTime: 5 Sekunden
```

### Motor-Parameter (für alle 32 Motoren identisch)

```
MaxSpeed: 2.0 m/s
MaxAcceleration: 2.0 m/s²
MaxDeceleration: 2.0 m/s²
```

## Verwendung

### 1. Simulation aktivieren

```
NewLineSim.SimulationEnabled := TRUE;
```

### 2. Betriebsart wählen

```
ManualMode := FALSE;  // Automatik-Modus
// oder
ManualMode := TRUE;   // Manuell-Modus
```

### 3. System freigeben

```
ExternalRelease := TRUE;
```

### 4. Überwachung

Beobachten Sie:
- `CurrentCycleTimeMs`: Aktuelle Zykluszeit
- `AverageCycleTimeMs`: Durchschnittliche Zykluszeit
- `NewLine_HW_StopSensor1` bis `NewLine_HW_StopSensor32`: Sensor-Zustände
- `NewLine_HW_Motor1_Run` bis `NewLine_HW_Motor32_Run`: Motor-Zustände

## Watchlist

Eine Watchlist-Datei für die Überwachung kann unter `watchlist/newline.mon` erstellt werden.

## Technische Details

- **Gesamtanzahl Förderbänder**: 32
- **Gesamtanzahl Motoren**: 32
- **Gesamtanzahl Sensoren**: 32
- **Simulationszeit für komplette Durchlauf**: ~21,7 Sekunden
- **Paket-Intervall**: 2 Sekunden
- **Shift-Register-Größe**: 230 Positionen
- **Shift-Intervall**: 100 Millisekunden

## Erweiterungen

Das System kann einfach erweitert werden durch:
- Anpassung der Förderband-Parameter in `NewLineProgram.st`
- Änderung der Simulation-Parameter in `NewLineSimulation.st`
- Hinzufügen von zusätzlichen Steuerungsfunktionen
- Integration von Reset-Mechanismen über `NewLine_ResetManager`
