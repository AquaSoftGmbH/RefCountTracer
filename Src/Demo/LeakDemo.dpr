program LeakDemo;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
{$APPTYPE CONSOLE}

{$R *.res}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  System.SysUtils,
  LeakDemo.Leak1 in 'LeakDemo.Leak1.pas',
  LeakDemo.Leak2 in 'LeakDemo.Leak2.pas';

begin
  LeakDemo.Leak2.Execute;
end.
