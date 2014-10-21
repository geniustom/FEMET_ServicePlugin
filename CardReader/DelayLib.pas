unit DelayLib;

interface
  uses Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,dialogs,forms;
  procedure Delay(msecs:integer);

var
  Mutex : THandle;

implementation

procedure Delay(msecs:integer);
var 
  Tick: DWord;
  Event: THandle;
begin
  Event := CreateEvent(nil, False, False, nil);
  try
    Tick := GetTickCount + DWord(msecs);
    while (msecs > 0) and (MsgWaitForMultipleObjects(1, Event, False, msecs, QS_ALLINPUT) <> WAIT_TIMEOUT) do
    begin
      Application.ProcessMessages;
      msecs := Tick - GetTickcount;
    end;
  finally
    CloseHandle(Event);
  end;
end;

end.
 