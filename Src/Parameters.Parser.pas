unit Parameters.Parser;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Be aware! this is code from 1999

interface

uses
  Classes, SysUtils;

const
  ParameterBegin: TSysCharSet = ['-', '/']; (* Zeichen mit denen der
                                                   Parameter beginnen darf,
                                                   sonst wird er als Datei-
                                                   name interpretiert *)
  ParameterDividable: TSysCharSet = ['''', '"']; (*Zeichen, die angeben, dass ein String weiter in Parameter
                                                      unterteilt werden kann*)

type
  TParseKind = (pkParameter, pkString);

  TParameterParser = class
  private
    FParams: TStringList;
    FParseKind: TParseKind;
    FText: string;
  protected
  public
    constructor Create(vParseKind: TParseKind);
    destructor Destroy; override;
    function Params: Boolean;
    (* Gibt True zurck, wenn Parameter angegeben wurden *)
    function GetParam(c: Char): string;
    (* Gibt den vollst„ndigen Paramter (beginnend mit "-") "c" wieder. Ist der
    Parameter nicht vorhanden, wird ein leerer String zurckgegeben. *)
    function Param(c: Char): Boolean;
    (* Gibt True zurck, wenn der Parameter "c" vorhanden ist. *)
    function FileNameCount: Integer;
    (* Z„hlt die Anzahl der Dateinamen. Dateinamen sind zu erkennen, da sie kein
    "-" vorangestellt haben. *)
    function GetFileName(Nr: Integer): string;
    (* Liefert den "Nr"sten Dateinamen zurck. Ist kein "Nr"ster Dateiname vor-
    handen, wird ein Leerer String zurckgegeben. Die Zählung beginnt bei 1.*)
    function GetParamFileName(c: Char): string;
    (* Gibt den Dateinamen der Form -"c"Dateiname zurck *)
    procedure FreeParameters;
    (* Gibt den Belegten Speicher fr die Parameter wieder frei *)
    function PParamStr(Nr: Integer): string;
    (* Gibt den Parameter "Nr" aus der internen (uniteigenen) Parameterliste zurck *)
    function AllParameters: string;
    (* Liefert alle Parameter zurück, wie sie der EXE-Datei übergeben wurden, ohne
    den EXE-Dateiname *)
    procedure GetParameters;
    function Count: Integer;
    (*Nur aufgrund der Rückwärtskompatibilität public*)
    property ParseKind: TParseKind read FParseKind write FParseKind;
    property Text: string read FText write FText;
    property MyParams: TStringList read FParams write FParams;
  end;

implementation

uses
{$IFDEF TESTING}
  Parameters.Parser.Test,
{$ENDIF}
  StrUtils;

function KillBeginEndSpaces(Src: string): string;
begin
  while (Length(Src) > 0) and (Src[1] = ' ') do
    Delete(Src, 1, 1);
  while (Length(Src) > 0) and (Src[Length(Src)] = ' ') do
    Delete(Src, Length(Src), 1);
  Result := Src;
end;

procedure KillBeginEndSpacesInList(var Src: TStringList);
var
  i: Integer;
begin
  for i := 0 to Src.Count - 1 do
    KillBeginEndSpaces(Src[i]);
end;

// Nächstes Vorkommen einer Zeichenkette ab einer frei definierbaren Stelle im String
function NextPos(SearchStr, Str: string; Position: integer): integer;
begin
  delete(Str, 1, Position - 1);
  Result := pos(SearchStr, upperCase(Str));
  if Result = 0 then exit;
  if (Length(Str) > 0) and (Length(SearchStr) > 0) then
    Result := Result + Position + 1;
end;

{ TParameterParser }

function TParameterParser.Count: Integer;
begin
  Result := FParams.Count;
end;

function GetCommandLine: string;
{$IFDEF MSWINDOWS}
begin
  Result := CmdLine;
end;
{$ELSE}
var
  i: Integer;
begin
  Result := '';
  for i := 0 to ParamCount - 1 do
  begin
    if Result <> '' then
      Result := Result + ' ';

    Result := Result + ParamStr(i);
  end;
end;
{$ENDIF}

constructor TParameterParser.Create(vParseKind: TParseKind);
begin
  FParseKind := vParseKind;
  if FParseKind = pkParameter then
    FText := GetCommandLine
  else
    FText := '';

  FParams := TStringList.Create;
  GetParameters;
end;

destructor TParameterParser.Destroy;
begin
  FreeAndNil(FParams);
end;

function TParameterParser.AllParameters: string;
var
  TmpText: TStringList;
begin
  if FParseKind = pkParameter then
    Result := FText
  else
  begin
    TmpText := TStringList.Create;
    try
      TmpText.Text := FParams.Text;
      TmpText.Delete(0);
      Result := TmpText.Text;
    finally
      TmpText.Free;
    end;
  end;
end;

function TParameterParser.FileNameCount: Integer;
var
  i: Integer;
  Count: Integer;
  s: string;
  StartAt: Integer;
begin
  Count := 0;
  if FParseKind = pkParameter then
    StartAt := 1
  else
    StartAt := 0;

  for i := StartAt to FParams.Count - 1 do
  begin
    s := PParamStr(i);
    if (Length(s) > 0) and not CharInSet(s[1], ParameterBegin) then
      Inc(Count);
  end;
  Result := Count;
end;

procedure TParameterParser.FreeParameters;
begin
  FParams.Clear;
end;

function TParameterParser.GetFileName(Nr: Integer): string;
var
  i: Integer;
  Count: Integer;
  s: string;
  StartAt: integer;
begin
  Result := '';
  if FParseKind = pkParameter then
    StartAt := 1
  else
    StartAt := 0;

  Count := 0;
  for i := StartAt to FParams.Count - 1 do
  begin
    s := PParamStr(i);
    if s <> '' then
    begin
      if not CharInSet(s[1], ParameterBegin) then
      begin
        Inc(Count);
        if Count = Nr then
        begin
          Result := s;
          Exit;
        end;
      end;
    end;
  end;
end;

function TParameterParser.GetParam(c: Char): string;
var
  i: Integer;
  s: string;
begin
  Result := '';
  if Params then
  begin
    for i := 0 to FParams.Count - 1 do
    begin
      s := PParamStr(i);
      if (Length(s) > 0) and CharInSet(s[1], ParameterBegin) then
        if Length(s) > 1 then
        begin
          if UpCase(s[2]) = UpCase(c) then
          begin
            Result := s;
            Exit; (* Funktion verlassen *)
          end;
        end;
    end;
  end;
end;

function TParameterParser.GetParamFileName(c: Char): string;
var
  s: string;
begin
  s := GetParam(c);
  if Length(s) > 0 then
    Delete(s, 1, 2);
  Result := s;
end;

function TParameterParser.Param(c: Char): Boolean;
begin
  Param := GetParam(c) <> '';
end;

function TParameterParser.Params: Boolean;
begin
  Params := FParams.Count > 1;
end;

function TParameterParser.PParamStr(Nr: Integer): string;
begin
  Result := FParams[Nr];
end;

/// <summary>
/// Liefert das erste in einem String vorkommende Trennzeichen (" oder ')
/// <summary>
/// <param name="vString">ein zu durchsuchender String</param>
/// <returns>Das erste gefundene Trennzeichen</returns>
function GetFirstDividerChar(vString: string): Char;
var
  i: Integer;
begin
  Result := ' ';
  for i := 1 to Length(vString) do
  begin
    if CharInSet(vString[i], ParameterDividable) then
    begin
      Result := vString[i];
      Break;
    end;
  end;
end;

function DividersLeft(vString: string): Boolean;
begin
  Result := False;
  if (Pos('"', vString) <> 0) or (NextPos('"', vString, Pos('"', vString) + 1) <> 0) then
  begin
    Result := True;
    Exit;
  end;

  if (Pos('''', vString) <> 0) or (NextPos('''', vString, Pos('''', vString) + 1) <> 0) then
    Result := True;
end;

/// <summary>
/// Liefert True, wenn in einem gegeben String mindestens zwei aufeinanderfolgende Trennzeichen (d.h. " oder ') vorkommen.
/// <summary>
/// <param name="vString">Ein zu durchsuchender String</param>
/// <returns>
/// True, wenn zwei aufeinanderfolgende Trennzeichen gefunden wurden, sonst False.
/// </returns>
function TwoDividersLeft(vString: string): Boolean;
begin
  Result := False;

  if (Pos('"', vString) <> 0) and (NextPos('"', vString, Pos('"', vString) + 1) <> 0) then
  begin
    Result := True;
    Exit;
  end;

  if (Pos('''', vString) <> 0) and (NextPos('''', vString, Pos('''', vString) + 1) <> 0) then
  begin
    Result := True;
    Exit;
  end;
  {
  if (Pos(' ', vString) <> 0) and (NextPos(' ', vString, Pos(' ', vString) + 1) <> 0) then
    Result := True;
    }
    {
  Result := False;
  if vString[1] in ParameterDividable then
  begin
    vString := Copy(vString, Pos(vString[1], vString) + 1, Length(vString));
    Result := vString[1] in ParameterDividable;
  end;      }
end;

procedure TParameterParser.GetParameters;
var
  TmpText: string;
  TmpChar: Char;
  OldText: string;
begin
  if FText <> '' then
  begin
    FParams.Clear;
    TmpText := FText;
    while (TmpText <> '') and TwoDividersLeft(TmpText) do
    begin
      TmpChar := GetFirstDividerChar(TmpText);
      //Parameter ohne Anführungszeichen
      if (Pos(TmpChar, TmpText) <> 0) and (Copy(TmpText, 0, Pos(TmpChar, TmpText) - 1) <> '') then
      begin
        FParams.Add(Copy(TmpText, 0, Pos(' ', TmpText) - 1));
        OldText := TmpText;
        TmpText := Copy(TmpText, Pos(' ', TmpText) + 1, Length(TmpText));
        if OldText = TmpText then
          Break;
      end
      else
      //Parameter mit Anführungszeichen
      begin
        FParams.Add(Copy(TmpText, Pos(TmpChar, TmpText) + 1, NextPos(TmpChar, TmpText, 2) - Pos(TmpChar, TmpText) - 3));
        TmpText := Copy(TmpText, NextPos(TmpChar, TmpText, Pos(TmpChar, TmpText) + 1), Length(TmpText));
      end;
    end;

    //Übriggebliebene Parameter anhand der Spaces trennen
    while (TmpText <> '') and (Pos(' ', TmpText) <> 0) do
    begin
      FParams.Add(Copy(TmpText, 0, Pos(' ', TmpText) - 1));
      TmpText := Copy(TmpText, Pos(' ', TmpText) + 1, Length(TmpText));
    end;
  end;

  if TmpText <> '' then
    FParams.Add(TmpText);

  KillBeginEndSpacesInList(FParams);
end;

end.

