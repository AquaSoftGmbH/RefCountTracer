{$H-}
unit Parameters;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.


// Be aware! this is code from 1999

(****************************************************************************
 *                            Unit Parameters                               *
 ****************************************************************************
 * Funtioniert sowohl unter BP/TP 7, als auch unter Delphi                  *
 *                                                                          *
 * Diese Unit hilft, die Parameter auszuwerten, die hinter den Dateinamen-  *
 * geschrieben wurden. Die Groá- und Kleinschreibung ist dabei egal.        *
 * Es werden nicht die Original-Routinen zur Parameterauswertung verwendet, *
 * da diese eine Konstruktion wie test.exe "Hallo Leute" -q als "Hallo,     *
 * Leute", -q (als 3 Param.) auswerten wrden. D.h. Parameter mit Leer-     *
 * Zeichen sind m”glich. Die Anfhrungszeichen werden automatisch entfernt. *
 * Als Anfhrungszeichen gelten sowohl " als auch '. Windows entfernt "     *
 * allerdings automatisch.                                                  *
 *                                                                          *
 * Die Parameter k”nnen die folgende Form haben:                            *
 * -x          Schalter an            z.B.: -x                              *
 * Dateiname   Dateiname              z.B.: Test.dat                        *
 * -xDateiname Schalter mit Dateiname z.B.: -xTest.dat                      *
 * Fr "Dateiname" k”nnen natrlich auch beliebige andere Daten stehen z.B. *
 * -x1234                                                                   *
 *                                                                          *
 * z.B: Test.exe hallo.txt -a -sTest.scr -z100                              *
 ****************************************************************************)


interface

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


///	<summary>
///	  Liefert den "Nr"sten Dateinamen zurück (die Zählung beginnt bei 1). Ist
///	  kein "Nr"ster Dateiname vorhanden, wird ein leerer String zurückgegeben.
///	</summary>
///	<param name="Nr">
///	  1 = erster Dateiname
///	</param>
function GetFileName(Nr: Integer): string;
function GetParamFileName(c: Char): string;
    (* Gibt den Dateinamen der Form -"c"Dateiname zurck *)
procedure FreeParameters;
    (* Gibt den Belegten Speicher fr die Parameter wieder frei *)
function PParamStr(Nr: Integer): string;
    (* Gibt den Parameter "Nr" aus der internen (uniteigenen) Parameterliste zurck *)
procedure UseOwnParameterParser(Own: Boolean);
    (* Ob der eigene Parser benutzt werden soll, Achtung: unter Windows ist es meist
    wenig sinnvoll, da Windows automatisch in " eingeschlossene Parameter als
    einen Parameter zurückliefert. Wenn man allerdings ' ebenfalls nutzen möchte,
    ist der eigene Parser dennoch sinnvoll. *)
function AllParameters: string;
    (* Liefert alle Parameter zurück, wie sie der EXE-Datei übergeben wurden, ohne
    den EXE-Dateiname *)

implementation

uses
  Parameters.Parser;

var
  FParameterParser: TParameterParser;

function GetParameterParser: TParameterParser;
begin
  if not Assigned(FParameterParser) then
    FParameterParser := TParameterParser.Create(pkParameter);
  Result := FParameterParser;
end;

function AllParameters: string;
begin
  Result := GetParameterParser.AllParameters;
end;

procedure FreeParameters;
begin
  GetParameterParser.FreeParameters;
end;

procedure GetParameters;
begin
  GetParameterParser.GetParameters;
end;

procedure UseOwnParameterParser(Own: Boolean);
(* Ob der eigene Parser benutzt werden soll *)
begin
  //Nur zur Rückwärtskompatibilität vorhanden
end;

function PParamStr(Nr: Integer): string;
begin
  Result := GetParameterParser.PParamStr(Nr);
end;

function Params: Boolean;
(* Gibt True zurck, wenn Parameter angegeben wurden *)
begin
  Result := GetParameterParser.Params;
end;

function GetParam(c: Char): string;
(* Gibt den vollst„ndigen Paramter (beginnend mit "-") "c" wieder. Ist der
   Parameter nicht vorhanden, wird ein leerer String zurckgegeben. *)
begin
  Result := GetParameterParser.GetParam(c);
end;

function Param(c: Char): Boolean;
(* Gibt True zurck, wenn der Parameter "c" vorhanden ist. *)
begin
  Result := GetParameterParser.Param(c);
end;

function FileNameCount: Integer;
(* Z„hlt die Anzahl der Dateinamen. Dateinamen sind zu erkennen, da sie kein
   "-" vorangestellt haben. *)
begin
  Result := GetParameterParser.FileNameCount;
end;

function GetFileName(Nr: Integer): string;
(* Liefert den "Nr"sten Dateinamen zurck. Ist kein "Nr"ster Dateiname vor-
   handen, wird ein Leerer String zurckgegeben. *)
begin
  Result := GetParameterParser.GetFileName(Nr);
end;

function GetParamFileName(c: Char): string;
(* Gibt den Dateinamen der Form -"c"Dateiname zurck *)
begin
  Result := GetParameterParser.GetParamFileName(c);
end;

initialization

finalization
  if Assigned(FParameterParser) then
    FParameterParser.Free;
end.

