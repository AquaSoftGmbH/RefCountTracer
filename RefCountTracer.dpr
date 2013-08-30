program RefCountTracer;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Tracer.Tree in 'Src\Tracer.Tree.pas',
  Tracer.InternString in 'Src\Tracer.InternString.pas',
  Tracer.Consts in 'Src\Tracer.Consts.pas',
  Tracer.Tools in 'Src\Tracer.Tools.pas',
  Tracer.Tree.Tools in 'Src\Tracer.Tree.Tools.pas',
  TestFramework.TestRunner in 'Src\TestFramework.TestRunner.pas',
  Tracer.CommandLine in 'Src\Tracer.CommandLine.pas';

begin
  {$IFDEF TESTING}
  // To run the unittests:
  // - compile with define TESTING
  // - start the executeable with "-u"-Parameter, e.g. RefCountTracer.exe -u
  // - its always good to compile the tests while developing so syntax errors
  //   are catched early. Just don't add "-u" parameter.

  if RunTests <> rtrSkipped then
    Exit; // Exit application after unit tests run
  {$ENDIF}

  ExecuteCommandLineInterface;
end.

