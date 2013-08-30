unit TestFramework.TestRunner;

interface

type
  TRunTestsResults = (rtrSkipped, rtrOk, rtrFailure);

function RunTests: TRunTestsResults;

{$IFDEF TESTING}

implementation

uses
  Parameters,
  {$IFDEF CONSOLE}
  TextTestRunner,
  {$ELSE}
  GUITestRunner,
  {$ENDIF}
  TestFramework;

const
  BoolToRunResult: array[Boolean] of TRunTestsResults = (rtrFailure, rtrOk);

{$IFDEF CONSOLE}
function RunText: Boolean;
begin
  with TextTestRunner.RunRegisteredTests do
    Free;
  ReadLn; // let us see the results
  Result := True; // Todo: reflect test result
end;
{$ELSE}
function RunGUI: Boolean;
begin
  GuiTestRunner.RunRegisteredTests;
  Result := True; // Todo: reflect test result
end;
{$ENDIF}

function RunTests: TRunTestsResults;
begin
  if not Param('u') then
    Exit(rtrSkipped);

  {$IFDEF CONSOLE}
  Result := BoolToRunResult[RunText];
  {$ELSE}
  Result := BoolToRunResult[RunGUI];
  {$ENDIF}

end;

{$ELSE}

implementation

function RunTests: TRunTestsResults;
begin
  Result := rtrSkipped;
end;

{$ENDIF}

end.
