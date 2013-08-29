unit Tracer.InterfacedObject;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

type
  TTracerInterfacedObject = class(TObject, IInterface)
  protected
    FRefCount: Integer;
{$IFDEF DEBUG}
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
{$IFDEF DEBUG}
//  DebugTools,
  Windows,
  Tracer.Logger,
{$ENDIF}
  SysUtils;

{ TTracerInterfacedObject }

function TTracerInterfacedObject._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
  {$IFDEF DEBUG}
//  if Self.ClassNameIs('TSelectionGroup') and (FInstanceID = 9999) then
  begin
    RefCountTracerLog.LogStackTrace(Self, 1);
//    OutputDebugString(PChar(Format('%s(%p)._AddRef -> RefCount = %d', [Self.ClassName, Pointer(Self), FRefCount])));
  end;
  {$ENDIF}
end;

function TTracerInterfacedObject._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  {$IFDEF DEBUG}
//  if Self.ClassNameIs('TSelectionGroup') and (FInstanceID = 9999)  then
  begin
    RefCountTracerLog.LogStackTrace(Self, -1);
//    OutputDebugString(PChar(Format('%s(%p)._Release -> RefCount = %d', [Self.ClassName, Pointer(Self), FRefCount])));
  end;
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
  AtomicDecrement(FRefCount);
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
