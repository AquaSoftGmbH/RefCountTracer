unit Tracer.Logger;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

{$INCLUDE Tracer.Logger.inc}

uses
  System.Classes;

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

    ///	<summary>
    ///	  A helper function for parsing a string containing several lines. It
    ///	  returns line by line with every call.
    ///	</summary>
    function NextLine(const Token: string; var Offset: Integer; out Line: string): Boolean;
    function PointerToHex(const Ptr: Pointer): string;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure LogStackTrace(const Instance: TObject; const RefCountChange: Integer);
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
  Tracer.Consts;

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
end;

destructor TRefCountTracerLog.Destroy;
begin
  FLog.SaveToFile('refcounttrace.txt');

  FLog.Free;

  inherited;
end;

procedure TRefCountTracerLog.LogStackTrace(const Instance: TObject; const RefCountChange: Integer);
begin
  FLog.Add(TraceLogDelimiter);
  // Key
  FLog.Add('$' + PointerToHex(Instance) + ': ' + Instance.UnitName + '.' + Instance.ClassName);
  // RefCount-Change
  FLog.Add('refcountchange: ' + IntToStr(RefCountChange));
  // Log
  DoLogStackTrace;
end;

function TRefCountTracerLog.NextLine(const Token: string; var Offset: Integer;
  out Line: string): Boolean;
var
  Index: Integer;
begin
  Index := Pos(#13#10, Token, Offset + 1);
  if Index = 0 then
  begin
    if Offset + 1 < Length(Token) then
      Index := Length(Token) + 1 else
      Exit(False); // nothing found
  end;

  Line := Copy(Token, Offset + 1, Index - (Offset + 1));
  Inc(Offset, 2); // Skip Delimiter

  if Line = '' then
  begin // Skip empty lines
    Result := NextLine(Token, Offset, Line);
  end else
  begin
    Inc(Offset, Length(Line));
    Result := True;
  end;
end;

function TRefCountTracerLog.PointerToHex(const Ptr: Pointer): string;
const
  {$IFDEF CPUX64}
  MaxHexLength = 16;
  {$ELSE}
  MaxHexLength = 8;
  {$ENDIF}
begin
  Result := IntToHex(NativeInt(Ptr), MaxHexLength);
end;

initialization
finalization
  if _RefCountTracerLog <> nil then
  begin
    FreeAndNil(_RefCountTracerLog);
  end;
end.

