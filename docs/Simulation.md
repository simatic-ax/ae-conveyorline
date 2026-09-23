# Conveyor Line Simulation mit Schieberegister

## Übersicht

Die Conveyor Line Simulation verwendet ein **Schieberegister-Verfahren**, um den zeitlichen Verlauf von Paketen auf der Förderbandlinie realistisch zu simulieren. Das Schieberegister wird in festen Zeitintervallen aktualisiert und repräsentiert die Position von Paketen über die Zeit.

## Schieberegister-Konzept

### Grundprinzip

Das Schieberegister ist ein Array von 70 BOOL-Werten, wobei jede Position 100ms Laufzeit repräsentiert:

```
Position 0  → Eingang (neues Paket)
Position 13 → Sensor 1 (nach 1.33s)
Position 26 → Sensor 2 (nach 2.66s)
Position 39 → Sensor 3 (nach 3.99s)
Position 52 → Sensor 4 (nach 5.32s)
Position 69 → Ausgang (nach 6.9s)
```

### Zeitliche Parameter

- **Shift-Intervall**: 100ms (SHIFT_INTERVAL)
- **Register-Größe**: 70 Positionen (7 Sekunden Gesamtlaufzeit)
- **Paketintervall**: 20 Positionen = 2 Sekunden (PACKAGE_INTERVAL_POSITIONS)
- **Sensor-Fenster**: 5 Positionen = 500ms (Paket-Präsenz am Sensor)

### Berechnung der Sensorpositionen

Basierend auf:
- **Förderbandlänge**: 2.0 Meter
- **Fördergeschwindigkeit**: 1.5 m/s
- **Laufzeit pro Förderband**: 2.0m / 1.5m/s = 1.33s = 13.3 Positionen (≈ 13)

```
Sensor 1: Position  0 (Start)
Sensor 2: Position 13 (nach 1.33s)
Sensor 3: Position 26 (nach 2.66s)
Sensor 4: Position 39 (nach 3.99s)
Sensor 5: Position 52 (nach 5.32s)
```

## Funktionsweise

### 1. Schieberegister-Update (alle 100ms)

```st
// Alle Positionen um eine Stelle nach rechts verschieben
FOR i := (REGISTER_SIZE - 1) TO 1 BY -1 DO
    _shiftRegister[i] := _shiftRegister[i - 1];
END_FOR;
```

### 2. Paketgenerierung

Alle 2 Sekunden (20 × 100ms) wird ein neues Paket an Position 0 eingefügt:

```st
_packageCounter := _packageCounter + 1;
IF _packageCounter >= PACKAGE_INTERVAL_POSITIONS THEN
    _shiftRegister[0] := TRUE; // Neues Paket
    _packageCounter := 0;
ELSE
    _shiftRegister[0] := FALSE;
END_IF;
```

### 3. Sensor-Auswertung

Jeder Sensor prüft ein Fenster von 5 Positionen (500ms):

```st
// Sensor ist aktiv, wenn irgendeine Position im Fenster TRUE ist
Sensor1 := CheckSensorWindow(_sensor1Position);
```

Die Methode `CheckSensorWindow` prüft, ob in den 5 Positionen ab der Sensorposition ein Paket vorhanden ist.

## Visualisierung des Schieberegisters

```
Zeit:     0ms   100ms  200ms  300ms  400ms  ...  1300ms  ...  2600ms
Position: [0]   [1]    [2]    [3]    [4]    ...  [13]    ...  [26]
          ↓     ↓      ↓      ↓      ↓           ↓            ↓
Paket:    [1]→  [1]→   [1]→   [1]→   [1]→   ... [1]      ... [1]
                                                  ↑            ↑
                                              Sensor1      Sensor2
```

## Implementierung

### Datei: [`ConveyorSimulation.st`](../src/ConveyorSimulation.st:1)

**Hauptkomponenten:**

1. **Schieberegister**: `_shiftRegister : ARRAY[0..69] OF BOOL`
2. **Shift-Timer**: `_shiftTimer : OnDelay` (triggert alle 100ms)
3. **Paket-Zähler**: `_packageCounter : INT` (zählt bis 20 für 2s Intervall)
4. **Sensor-Positionen**: Konstanten für jede Sensorposition
5. **Sensor-Fenster**: 5 Positionen für Paket-Detektion

### Integration in [`MainProgram.st`](../src/MainProgram.st:76-90)

```st
// 0. Update simulation (if enabled, overwrites HW inputs)
ConveyorSim.Update();

// If simulation is enabled, use simulated sensor values
IF ConveyorSim.SimulationEnabled THEN
    HW_StopSensor1 := ConveyorSim.Sensor1;
    HW_StopSensor2 := ConveyorSim.Sensor2;
    HW_StopSensor3 := ConveyorSim.Sensor3;
    HW_StopSensor4 := ConveyorSim.Sensor4;
    HW_StopSensor5 := ConveyorSim.Sensor5;
END_IF;
```

## Verwendung

### Simulation aktivieren

```st
ConveyorSim.SimulationEnabled := TRUE;
```

### Simulation deaktivieren

```st
ConveyorSim.SimulationEnabled := FALSE;
```

Beim Deaktivieren wird das Schieberegister zurückgesetzt und alle Sensorsignale werden auf FALSE gesetzt.

### Debugging: Schieberegister-Status abfragen

```st
// Prüfe Position 13 (Sensor 1)
packageAtSensor1 := ConveyorSim.GetRegisterState(13);
```

## Vorteile des Schieberegister-Ansatzes

1. **Zeitlich präzise**: Exakte Simulation des Materialflusses über die Zeit
2. **Mehrere Pakete**: Kann mehrere Pakete gleichzeitig auf der Linie simulieren
3. **Realistische Abstände**: Pakete haben definierte Abstände (2 Sekunden)
4. **Sensor-Fenster**: Realistische Sensor-Triggerzeit (500ms)
5. **Nachvollziehbar**: Schieberegister kann für Debugging ausgelesen werden
6. **Skalierbar**: Einfach anpassbar für andere Geschwindigkeiten/Längen

## Anpassung der Parameter

### Paketintervall ändern

Um die Frequenz der Pakete zu ändern (z.B. alle 3 Sekunden):

```st
PACKAGE_INTERVAL_POSITIONS : INT := 30; // 3s / 100ms = 30 Positionen
```

### Shift-Intervall ändern

Um die Auflösung zu erhöhen (z.B. 50ms):

```st
SHIFT_INTERVAL : TIME := T#50ms;
REGISTER_SIZE : INT := 140; // 7s / 50ms = 140 Positionen
```

**Wichtig**: Bei Änderung des Shift-Intervalls müssen auch die Sensorpositionen neu berechnet werden!

### Sensor-Fenster ändern

Um die Sensor-Triggerzeit zu ändern (z.B. 1 Sekunde):

```st
_sensorWindow : INT := 10; // 1s / 100ms = 10 Positionen
```

### Förderbandlänge und Geschwindigkeit ändern

```st
CONVEYOR_LENGTH : LREAL := 3.0; // 3 Meter
CONVEYOR_SPEED : LREAL := 2.0;  // 2 m/s
```

**Wichtig**: Sensorpositionen müssen neu berechnet werden:
```
Laufzeit = 3.0m / 2.0m/s = 1.5s
Positionen = 1.5s / 0.1s = 15 Positionen

_sensor1Position := 0;
_sensor2Position := 15;
_sensor3Position := 30;
_sensor4Position := 45;
_sensor5Position := 60;
```

## Zeitlicher Ablauf (Beispiel)

```
Zeit    | Position | Sensor1 | Sensor2 | Sensor3 | Sensor4 | Sensor5
--------|----------|---------|---------|---------|---------|--------
0.0s    | 0        | TRUE    | FALSE   | FALSE   | FALSE   | FALSE
1.3s    | 13       | FALSE   | TRUE    | FALSE   | FALSE   | FALSE
2.6s    | 26       | FALSE   | FALSE   | TRUE    | FALSE   | FALSE
3.9s    | 39       | FALSE   | FALSE   | FALSE   | TRUE    | FALSE
5.2s    | 52       | FALSE   | FALSE   | FALSE   | FALSE   | TRUE
6.9s    | 69       | FALSE   | FALSE   | FALSE   | FALSE   | FALSE
```

Nach 2 Sekunden wird das nächste Paket generiert, sodass mehrere Pakete gleichzeitig auf der Linie sein können.

## Watchlist für Monitoring

Fügen Sie folgende Variablen zur Watchlist hinzu:

```
ConveyorSim.SimulationEnabled
ConveyorSim.Sensor1
ConveyorSim.Sensor2
ConveyorSim.Sensor3
ConveyorSim.Sensor4
ConveyorSim.Sensor5
ConveyorSim._packageCounter
ConveyorSim._shiftRegister[0]   // Eingang
ConveyorSim._shiftRegister[13]  // Sensor 1 Position
ConveyorSim._shiftRegister[26]  // Sensor 2 Position
ConveyorSim._shiftRegister[39]  // Sensor 3 Position
ConveyorSim._shiftRegister[52]  // Sensor 4 Position
```

## Deployment Status

✅ **Build**: Erfolgreich kompiliert (0 Fehler)
✅ **Deployment**: Erfolgreich auf PLC_1 (192.168.0.1) deployed
✅ **Memory Usage**: Code: 3.9%, Data: 0.3%

## Troubleshooting

**Problem**: Sensoren werden nicht getriggert
- **Lösung**: Stellen Sie sicher, dass `ConveyorSim.SimulationEnabled = TRUE`
- **Lösung**: Überprüfen Sie, dass `ConveyorSim.Update()` zyklisch aufgerufen wird

**Problem**: Pakete erscheinen nicht regelmäßig
- **Lösung**: Prüfen Sie `_packageCounter` - sollte von 0 bis 19 zählen
- **Lösung**: Überprüfen Sie den Shift-Timer

**Problem**: Sensoren bleiben zu lange aktiv
- **Lösung**: Reduzieren Sie `_sensorWindow` (z.B. auf 3 Positionen = 300ms)

**Problem**: Pakete bewegen sich zu schnell/langsam
- **Lösung**: Passen Sie `SHIFT_INTERVAL` an (kleinerer Wert = schneller)
