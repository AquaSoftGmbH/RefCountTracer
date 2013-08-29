unit Parameters.Parser.Test;

interface

{$I CheckTestFramework.inc}

uses
  TestFramework, 
  Parameters.Parser;

type
  TTestParameterParser = class(TTestCase)
  private
    { Private-Deklarationen }
  public
    Parser: TParameterParser;

    procedure SetUp; override;
    procedure TearDown; override;
  protected
    { Protected-Deklarationen }
  published
   { Published-Deklarationen }

    // Testcases hier
    procedure Test_SingleQuotes;
  end;

implementation

{ TTestParameterParser }

procedure TTestParameterParser.SetUp;
begin
  inherited;
  Parser := TParameterParser.Create(pkString);
end;

procedure TTestParameterParser.TearDown;
begin
  inherited;
  Parser.Free;
end;

procedure TTestParameterParser.Test_SingleQuotes;
begin
  Parser.Text := 'c:\test.exe ''-pd:\Sources\Delphi\Applications\DiaShow\7.x\Bin\Plugins\DiaShowManager.Plg -sManual''';
  Parser.GetParameters;

  CheckEquals('c:\test.exe', Parser.PParamStr(0));
  CheckEquals('-pd:\Sources\Delphi\Applications\DiaShow\7.x\Bin\Plugins\DiaShowManager.Plg -sManual', Parser.PParamStr(1));
end;

initialization
  RegisterTest(TTestParameterParser.Suite);
end.
