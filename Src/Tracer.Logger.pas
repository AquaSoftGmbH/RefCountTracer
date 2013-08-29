unit Tracer.Logger;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

uses
  System.Classes;

type
  TRefCountTracerLog = class
  protected
    FLog: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LogStackTrace(const Instance: TObject; const RefCountChange: Integer);
  end;

function RefCountTracerLog: TRefCountTracerLog;

implementation

uses
  MadStackTrace,
  System.SysUtils,
  Tracer.Consts;

var
  _RefCountTracerLog: TRefCountTracerLog = nil;

function RefCountTracerLog: TRefCountTracerLog;
begin
  if _RefCountTracerLog = nil then
    _RefCountTracerLog := TRefCountTracerLog.Create;

  Result := _RefCountTracerLog;
end;

{ TRefCountTracerLog }

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
const
  {$IFDEF CPUX64}
  MaxHexLength = 16;
  {$ELSE}
  MaxHexLength = 8;
  {$ENDIF}
begin
  FLog.Add(TraceLogDelimiter);
  // Key
  FLog.Add('$' + IntToHex(NativeInt(Instance), MaxHexLength) + ': ' + Instance.UnitName + '.' + Instance.ClassName);
  // RefCount-Change
  FLog.Add('refcountchange: ' + IntToStr(RefCountChange));
  // Log
  FLog.Add(StackTrace);
end;

initialization
finalization
  if _RefCountTracerLog <> nil then
  begin
    FreeAndNil(_RefCountTracerLog);
  end;
end.

