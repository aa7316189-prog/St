("
  PLC_PRG: резервирование двух насосов для ПЛК210 (Овен) в CoDeSys ST.
  Логика:
  - При команде StartCmd включается один насос.
  - Насосы чередуются по последнему использованному.
  - При аварии активного насоса происходит переключение на резервный (если он исправен).
  - При StopCmd оба насоса отключаются.
  - При аварии обоих насосов формируется сигнал BothFault и насосы отключаются.
")
PROGRAM PLC_PRG
VAR_INPUT
    StartCmd   : BOOL; (* Команда пуска *)
    StopCmd    : BOOL; (* Команда останова *)
    Pump1Fault : BOOL; (* Авария насоса 1 *)
    Pump2Fault : BOOL; (* Авария насоса 2 *)
END_VAR
VAR_OUTPUT
    Pump1Cmd   : BOOL; (* Команда на насос 1 *)
    Pump2Cmd   : BOOL; (* Команда на насос 2 *)
    BothFault  : BOOL; (* Авария обоих насосов *)
    ActivePump : INT;  (* 0 - нет, 1 - насос 1, 2 - насос 2 *)
END_VAR
VAR
    lastPump : INT := 1; (* последний активный насос для чередования *)
    runReq   : BOOL;
END_VAR

(* Формирование запроса работы *)
IF StopCmd THEN
    runReq := FALSE;
ELSIF StartCmd THEN
    runReq := TRUE;
END_IF

BothFault := Pump1Fault AND Pump2Fault;

IF NOT runReq THEN
    Pump1Cmd := FALSE;
    Pump2Cmd := FALSE;
    ActivePump := 0;
ELSIF BothFault THEN
    Pump1Cmd := FALSE;
    Pump2Cmd := FALSE;
    ActivePump := 0;
ELSE
    (* Переключение при аварии активного насоса или при первом пуске *)
    IF (ActivePump = 0)
        OR (ActivePump = 1 AND Pump1Fault)
        OR (ActivePump = 2 AND Pump2Fault) THEN
        IF lastPump = 1 THEN
            IF NOT Pump2Fault THEN
                ActivePump := 2;
            ELSE
                ActivePump := 1;
            END_IF
        ELSE
            IF NOT Pump1Fault THEN
                ActivePump := 1;
            ELSE
                ActivePump := 2;
            END_IF
        END_IF

        IF ActivePump = 1 THEN
            lastPump := 1;
        ELSE
            lastPump := 2;
        END_IF
    END_IF

    Pump1Cmd := (ActivePump = 1) AND NOT Pump1Fault;
    Pump2Cmd := (ActivePump = 2) AND NOT Pump2Fault;
END_IF
