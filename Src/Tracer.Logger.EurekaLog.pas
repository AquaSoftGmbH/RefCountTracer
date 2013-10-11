unit Tracer.Logger.EurekaLog;

interface

uses
  Classes,
  Tracer.Logger,
  ECallStack;

type
  TEurekaLogRefCountTracerLog = class(TRefCountTracerLog)
  protected
    procedure LogLine(const CallStack: TEurekaBaseStackList; const Index: Integer);
    procedure DoLogStackTrace; override;
  end;

implementation

uses
  SysUtils,
  EClasses;

{ TEurekaLogRefCountTracerLog }

procedure TEurekaLogRefCountTracerLog.DoLogStackTrace;
const
  Skip = 2; // Skip the unneeded Lines in the call stack (TEurekaLogRefCountTracerLog.DoLogStackTrace and its base class (TRefCountTracerLog.DoLogStackTrace))
var
  CallStack: TEurekaBaseStackList;
  i: Integer;
begin
  CallStack := EurekaCallStackClass.Create(TEurekaCallStack.GetCurrentInstruction); // Current location
  try
    for i := Skip to CallStack.Count - 1 do
      LogLine(CallStack, i);
  finally
    CallStack.Free;
  end;
end;

procedure TEurekaLogRefCountTracerLog.LogLine(
  const CallStack: TEurekaBaseStackList; const Index: Integer);
var
  Entry: TStackTraceEntry;
  Info_: TEurekaDebugInfo;
  Info: PEurekaDebugInfo;
begin
  Info := CallStack.GetItem(Index, Info_);

  Entry.Address := PointerToHex(Info.Location.Address);
  Entry.Module := ExtractFilename(Info.Location.ModuleName);
  Entry.UnitName := Info.Location.UnitName;
  if Info.Location.LineNumber <= 0 then
  begin
    Entry.Line := '';
  end else
    Entry.Line := IntToStr(Info.Location.LineNumber);

  Entry.FunctionName := Info.Location.ClassName;
  if Entry.FunctionName <> '' then
    Entry.FunctionName := Entry.FunctionName + '.';
  Entry.FunctionName := Entry.FunctionName + Info.Location.ProcedureName;

  AddStackTraceEntry(Entry);
end;

initialization
  RegisterStackTracer(TEurekaLogRefCountTracerLog);
end.
