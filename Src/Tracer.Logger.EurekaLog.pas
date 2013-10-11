unit Tracer.Logger.EurekaLog;

interface

uses
  Tracer.Logger;

type
  TEurekaLogRefCountTracerLog = class(TRefCountTracerLog)
    // Todo: Implement
  end;

implementation

initialization
  RegisterStackTracer(TEurekaLogRefCountTracerLog);
end.

