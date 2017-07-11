unit Tracer.InterfacedObject;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

{$IFDEF DEBUG}
  {$DEFINE ENABLE_LOGGING}
{$ENDIF}

uses
  Windows;

type
  TTracerInterfacedObject = class(TObject, IInterface)
  protected
    FRefCount: Integer;
{$IFDEF ENABLE_LOGGING}
    FInstanceID: Integer;
    class var InstanceCount: Integer;
{$ENDIF}
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property RefCount: Integer read FRefCount;
    class function NewInstance: TObject; override;
  end;

implementation

uses
{$IFDEF ENABLE_LOGGING}
  Tracer.Logger,
{$ENDIF}
  SysUtils;

{ TTracerInterfacedObject }

function TTracerInterfacedObject._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
  {$IFDEF ENABLE_LOGGING}
  RefCountTracerLog.LogStackTrace(Self, 1);
  {$ENDIF}
end;

function TTracerInterfacedObject._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  {$IFDEF ENABLE_LOGGING}
  RefCountTracerLog.LogStackTrace(Self, -1);
  {$ENDIF}
  if Result = 0 then
    Destroy;
end;

function TTracerInterfacedObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TTracerInterfacedObject.AfterConstruction;
begin
  // Release the constructor's implicit refcount
  InterlockedDecrement(FRefCount);
end;

procedure TTracerInterfacedObject.BeforeDestruction;
  procedure RaiseException;
  begin
    // Das Auslagern in eine kleine Unterfunktion erfüllt hier folgenden Zweck:
    // Es muss nur im Fehlerfall ein Exception-Frame erzeugt und verwaltet
    // werden (für die Freigabe des Strings in dieser Message) -> bessere
    // Performance.
    raise Exception.Create('Interface wird noch referenziert! ' + IntToStr(FRefCount) + ' ' + Classname);
    System.Error(reInvalidPtr);
  end;
begin
  if FRefCount <> 0 then
    RaiseException;
end;

class function TTracerInterfacedObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  TTracerInterfacedObject(Result).FRefCount := 1;
end;

end.
