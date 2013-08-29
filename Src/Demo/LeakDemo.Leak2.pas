unit LeakDemo.Leak2;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

procedure Execute;

implementation

uses
  Tracer.InterfacedObject,
  Tracer.Logger;

type
  IIntf1 = interface ['{05B62D7A-F43E-4D9F-8975-D4CB6CCF7C36}']
  end;

  TObj1 = class(TTracerInterfacedObject, IIntf1)
  public
    A: IInterface;
  end;

// A circular reference  
procedure Execute;
var
  Intf1: IInterface;
  Intf2: IInterface;
begin
  Intf1 := TObj1.Create;
  Intf2 := TObj1.Create;
  (Intf1 as TObj1).A := Intf2; // Intf1 holds Intf2
  (Intf2 as TObj1).A := Intf1; // Intf2 holds Intf1
end;

end.

