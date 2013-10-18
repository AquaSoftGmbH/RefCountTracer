unit TestFramework.BaseTestCase;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 

interface

uses
  TestFramework,
  System.Types;

type
  TBaseTestCase = class(TTestCase)
  public
    function FixtureDir(const TestCase: string = ''): string;
    // Summary:
    //   Liefert den Dateinamen einer Datei im Fixtureverzeichnis zurück.
    //   z.B. Fixture('Pictures\JPG\Picture01.jpg').
    function Fixture(const FixtureFilename: string; CheckIfExists: Boolean = True): string;
    function HomeDir: string;
    // Summary:
    //   Prüft, ob die Datei "Filename" vorhanden ist.
    // Arguments:
    //   Filename - zu prüfender Dateiname
    //   SizeGreaterZero - Wenn True, muss die Datei größer als 0 Byte sein,
    //                     sonst wird ein Fehler zurückgegeben
    procedure CheckFileExists(const Filename: string; const SizeGreaterZero: Boolean = True);
    procedure CheckFileContents(const Filename: string; const Text: string; const SizeGreaterZero: Boolean = True);

    // Summary:
    //   Prüft, ob das Verzeichnis "Dir" vorhanden ist.
    procedure CheckDirectoryExists(const Dir: string);
    // Summary:
    //   Prüft, ob das Verzeichnis "Dir" nicht vorhanden ist.
    procedure CheckNotDirectoryExists(const Dir: string);
    // Summary:
    //   Prüft, ob die Datei "Filename" nicht vorhanden ist.
    procedure CheckNotFileExists(const Filename: string);
    // Summary:
    //   Prüfen, ob der Formatstring mit den Argumenten "Args" auflösbar ist.
    //   So sollten alle Resourcestrings mit Platzhaltern geprüft werden, damit
    //   Fehler beim Übersetzen auffallen.
    procedure CheckFormat(const FormatStr: string; const Args: array of TVarRec);

    procedure CheckEqualsRectFuzzy(const expected, actual: TRect; delta: Integer; const msg: string = ''); overload;
    procedure CheckEqualsRectFuzzy(const expected, actual: TRectF; delta: Single; const msg: string = ''); overload;
    procedure CheckEqualsSizeFuzzy(const expected, actual: TSizeF; delta: Single; const msg: string = ''); overload;
    procedure CheckEqualsRect(const expected, actual: TRect; const msg: string = ''); overload;
    procedure CheckRange(const Left, Right: Integer; const Actual: Integer; const Msg: string = ''); overload;
    procedure CheckRange(const Left, Right: Single; const Actual: Single; const Msg: string = ''); overload;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils,
  System.Classes,
  System.IOUtils;

{ TBaseTestCase }

procedure TBaseTestCase.CheckDirectoryExists(const Dir: string);
begin
  Check(DirectoryExists(Dir), 'Verzeichnis "' + Dir + '" nicht gefunden');
end;

procedure TBaseTestCase.CheckEqualsRect(const expected, actual: TRect;
  const msg: string);
begin
  CheckEqualsRectFuzzy(expected, actual, 0, msg);
end;

procedure TBaseTestCase.CheckEqualsRectFuzzy(const expected, actual: TRectF;
  delta: Single; const msg: string);
begin
  CheckEquals(expected.Top, actual.Top, delta, 'Top: ' + msg);
  CheckEquals(expected.Bottom, actual.Bottom, delta, 'Bottom: ' + msg);
  CheckEquals(expected.Left, actual.Left, delta, 'Left: ' + msg);
  CheckEquals(expected.Right, actual.Right, delta, 'Right: ' + msg);
end;

procedure TBaseTestCase.CheckEqualsSizeFuzzy(const expected, actual: TSizeF;
  delta: Single; const msg: string);
begin
  CheckEquals(expected.cx, actual.cx, delta, 'CX: ' + msg);
  CheckEquals(expected.cy, actual.cy, delta, 'CY: ' + msg);
end;

procedure TBaseTestCase.CheckEqualsRectFuzzy(const expected, actual: TRect; delta: Integer; const msg: string);
begin
  CheckEquals(expected.Top, actual.Top, delta, 'Top: ' + msg);
  CheckEquals(expected.Bottom, actual.Bottom, delta, 'Bottom: ' + msg);
  CheckEquals(expected.Left, actual.Left, delta, 'Left: ' + msg);
  CheckEquals(expected.Right, actual.Right, delta, 'Right: ' + msg);
end;

procedure TBaseTestCase.CheckFileExists(const Filename: string; const SizeGreaterZero: Boolean);
  function FileSizeByFilename(const Filename: string): Int64;
  var
    F: TSearchRec;
  begin
    Result := -1;
    if FindFirst(Filename, faReadOnly + faHidden + faSysFile + faArchive, F) = 0 then
    begin
      {$IFDEF MSWINDOWS}
      Result := F.FindData.nFileSizeLow or (F.FindData.nFileSizeHigh shl 32);
      {$ELSE}
      Result := F.Size;
      {$ENDIF}
    end;
    System.SysUtils.FindClose(F);
  end;
begin
  Check(FileExists(Filename), 'Datei "' + Filename + '" nicht gefunden');
  if SizeGreaterZero then
    Check(FileSizeByFilename(Filename) > 0, 'Datei "' + Filename + '" muss größer als 0 Bytes sein');
end;

                                                                                                    // #4752
procedure TBaseTestCase.CheckFileContents(const Filename: string; const Text : string; const SizeGreaterZero: Boolean = True);

  function FileContents(const FileName : string) : string;
  var
    StringList: TStringList;
  begin
    Result := '';
    StringList := TStringList.Create;
    try
      StringList.LoadFromFile(FileName);
      Result := StringList.Text;
    finally
      FreeAndNil(StringList);
    end;
  end;


begin
  CheckFileExists(Filename, SizeGreaterZero);
  CheckEquals(Text, FileContents(FileName));
end;

procedure TBaseTestCase.CheckFormat(const FormatStr: string; const Args: array of TVarRec);
var
  s: string;
  i, PlaceholderCount: Integer;
begin
  // Anzahl der Platzhalter überprüfen
  s := StringReplace(FormatStr, '%%', '', [rfReplaceAll]); // "%%" steht als für "%" ->  entfernen

  // Anzahl der Platzhalter im String zählen
  PlaceholderCount := 0;
  for i := 1 to Length(s) do
    if s[i] = '%' then
      Inc(PlaceholderCount);

  // Vergleich, ob Platzahlteranzahl mit den Übergebenen übereinstimmt
  if Length(Args) <> PlaceholderCount then
    Fail('Ungültige Anzahl der Platzhalter (' + IntToStr(Length(Args)) + ' gefunden, ' + IntToStr(PlaceholderCount) + ' erwartet) in "' + FormatStr + '"');

  // Prüfen, ob Platzhalter funktionieren
  try
    s := Format(FormatStr, Args);
  except
    Fail('Ungültige Platzhalter in "' + FormatStr + '"');
  end;
end;

procedure TBaseTestCase.CheckNotDirectoryExists(const Dir: string);
begin
  Check(not DirectoryExists(Dir), 'Verzeichnis "' + Dir + '" ist vorhanden, obwohl es es nicht sein sollte.');
end;

procedure TBaseTestCase.CheckNotFileExists(const Filename: string);
begin
  Check(not FileExists(Filename), 'Datei "' + Filename + '" ist vorhanden, obwohl sie es nicht sein sollte.');
end;

procedure TBaseTestCase.CheckRange(const Left, Right, Actual: Integer;
  const Msg: string);
begin
  Check(Actual >= Left, Format('%d < %d (expected to be >=) %s', [Actual, Left, Msg]));
  Check(Actual <= Right, Format('%d > %d (expected to be <=) %s', [Actual, Right, Msg]));
end;

procedure TBaseTestCase.CheckRange(const Left, Right, Actual: Single;
  const Msg: string);
begin
  Check(Actual >= Left, Format('%f < %f (expected to be >=) %s', [Actual, Left, Msg]));
  Check(Actual <= Right, Format('%f > %f (expected to be <=) %s', [Actual, Right, Msg]));
end;

function TBaseTestCase.Fixture(const FixtureFilename: string; CheckIfExists: Boolean): string;
var
  TestCase: string;
  P: Integer;
begin
  Assert(FixtureFilename <> '');
  Assert(FixtureFilename[1] <> PathDelim);

  P := Pos(PathDelim, FixtureFilename);
  Assert(P <> 0);

  TestCase := Copy(FixtureFilename, 1, P);
  Result := TPath.Combine(FixtureDir(TestCase), Copy(FixtureFilename, P + 1, Length(FixtureFilename) - P));

  if CheckIfExists then
    if not FileExists(Result) then
      raise Exception.Create('File "' + Result + '" not found');
end;

function TBaseTestCase.FixtureDir(const TestCase: string): string;
var
  vStr: string;
begin
  vStr := IfThen(TestCase = '', Self.Classname, TestCase);
  Result := ExpandFileName(HomeDir + '..\TestFixtures\');
  if vStr <> '' then
    Result := TPath.Combine(Result, vStr);
end;

function TBaseTestCase.HomeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

end.
