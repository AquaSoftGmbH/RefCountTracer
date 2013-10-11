unit Tracer.Logger.JCLDebug;

interface

uses
  Tracer.Logger;

type
  TJCLDebugRefCountTracerLog = class(TRefCountTracerLog)
    // Todo: Implement
  end;

implementation

initialization
  RegisterStackTracer(TJCLDebugRefCountTracerLog);
end.
