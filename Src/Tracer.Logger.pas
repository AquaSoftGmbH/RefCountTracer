unit Tracer.Logger;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

{$INCLUDE Tracer.Logger.inc}

uses
  System.Classes,
  System.SyncObjs;

type
  TStackTraceEntry = record
    Address: string;
    Module: string;
    UnitName: string;
    Line: string;
    FunctionName: string;
  end;

  TRefCountTracerLog = class
  protected
    FLog: TStringList;
    FLock: TCriticalSection;

    ///	<summary>
    ///	  Adds a new line in the log for the stack trace.
    ///	</summary>
    procedure AddStackTraceEntry(const Entry: TStackTraceEntry);

    ///	<summary>
    ///	  Please override this function to write a new StackTracer (e.g. for
    ///	  MadExcept or EurekaLog). Internally call <c>AddStackTraceEntry</c>
    ///	  for every line of the call stack.
    ///	</summary>
    procedure DoLogStackTrace; virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    ///	<summary>
    ///	  Logs the RefCount Change of an Instance.
    ///	</summary>
    ///	<param name="RefCountChange">
    ///	  Set 1 for _AddRef and -1 for _Release
    ///	</param>
    ///	<param name="SkipStackTrace">
    ///	  If True no stacktrace is written. This can be useful for hand
    ///	  optimizations.
    ///	</param>
    procedure LogStackTrace(const Instance: TObject; const RefCountChange: Integer; const SkipStackTrace: Boolean = False);
  end;
  TRefCountTracerLogClass = class of TRefCountTracerLog;

procedure RegisterStackTracer(const StackTracerClass: TRefCountTracerLogClass);
function RefCountTracerLog: TRefCountTracerLog;

implementation

uses
  {$IFDEF LOGGER_MADEXCEPT}
  Tracer.Logger.madExcept,
  {$ENDIF}
  {$IFDEF LOGGER_EUREKALOG}
  Tracer.Logger.EurekaLog,
  {$ENDIF}
  {$IFDEF LOGGER_JCLDEBUG}
  Tracer.Logger.JCLDebug, // Todo
  {$ENDIF}
  System.SysUtils,
  Tracer.Consts, Tracer.Logger.Tools;

var
  _RefCountTracerLog: TRefCountTracerLog = nil;
  _StackTracerClass: TRefCountTracerLogClass = nil;

procedure RegisterStackTracer(const StackTracerClass: TRefCountTracerLogClass);
begin
  Assert((_StackTracerClass = nil) or (_StackTracerClass = StackTracerClass), 'Can only register one StackTracerClass');
  _StackTracerClass := StackTracerClass;
end;

function RefCountTracerLog: TRefCountTracerLog;
begin
  if (_RefCountTracerLog = nil) and (_StackTracerClass <> nil) then
    _RefCountTracerLog := _StackTracerClass.Create;

  Assert(_RefCountTracerLog <> nil);
  Result := _RefCountTracerLog;
end;

{ TRefCountTracerLog }

procedure TRefCountTracerLog.AddStackTraceEntry(const Entry: TStackTraceEntry);
begin
  FLog.Add(Format('%s'#9'%s'#9'%s'#9'%s'#9'%s', [
    Entry.Address,
    Entry.Module,
    Entry.UnitName,
    Entry.Line,
    Entry.FunctionName]));
end;

constructor TRefCountTracerLog.Create;
begin
  FLog := TStringList.Create;
  FLock := TCriticalSection.Create;
end;

destructor TRefCountTracerLog.Destroy;
begin
  FLog.SaveToFile('refcounttrace.txt');

  FLog.Free;
  FLock.Free;

  inherited;
end;

procedure TRefCountTracerLog.LogStackTrace(const Instance: TObject; const RefCountChange: Integer; const SkipStackTrace: Boolean);
begin
  FLock.Enter;
  try
    FLog.Add(TraceLogDelimiter);
    // Key
  //  FLog.Add('$' + PointerToHex(Instance) + ': ' + Instance.UnitName + '.' + Instance.ClassName);
    FLog.Add('$' + PointerToHex(Instance));
    // RefCount-Change
    FLog.Add('refcountchange: ' + IntToStr(RefCountChange));
    // Log
{    if not SkipStackTrace then
      DoLogStackTrace;}
  finally
    FLock.Leave;
  end;
end;

initialization
finalization
  if _RefCountTracerLog <> nil then
  begin
    FreeAndNil(_RefCountTracerLog);
  end;
end.

