unit Tracer.Tools.Test;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface

{$I CheckTestFramework.Inc}

uses
  TestFramework;

type
  TTracerToolsTest = class(TTestCase)
  public
    procedure TestParseReverseStringList;
  end;

implementation

uses
  System.Classes,
  Tracer.Tools;

{ TTracerToolsTest }

procedure TTracerToolsTest.TestParseReverseStringList;
var
  SL: TStringList;
begin
  SL := TStringList.Create;

  // reverse an even number of elements
  SL.Text := '1'#13#10'2'#13#10'3'#13#10'4'#13#10'5'#13#10'6'#13#10;
  ReverseOrder(SL);
  CheckEquals('6'#13#10'5'#13#10'4'#13#10'3'#13#10'2'#13#10'1'#13#10, SL.Text);

  // reverse an uneven number of elements
  SL.Add('0');
  ReverseOrder(SL);
  CheckEquals('0'#13#10'1'#13#10'2'#13#10'3'#13#10'4'#13#10'5'#13#10'6'#13#10, SL.Text);

  SL.Free;
end;

initialization
  RegisterTest(TTracerToolsTest.Suite);
end.

