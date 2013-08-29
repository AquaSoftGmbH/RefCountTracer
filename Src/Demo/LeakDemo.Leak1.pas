unit LeakDemo.Leak1;

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
  end;

// No Leak
procedure Execute;
var
  Intf1: IInterface;
begin
  Intf1 := TObj1.Create;
end;

end.
