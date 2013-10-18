unit Tracer.Logger.Tools;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 

interface

///	<summary>
///	  A helper function for parsing a string containing several lines. It
///	  returns line by line with every call.
///	</summary>
function NextLine(const Token: string; var Offset: Integer; out Line: string): Boolean;
function PointerToHex(const Ptr: Pointer): string;
function NativeIntToHex(const Value: NativeInt): string;

implementation

uses
  System.SysUtils;


function NextLine(const Token: string; var Offset: Integer;
  out Line: string): Boolean;
var
  Index: Integer;
begin
  Index := Pos(#13#10, Token, Offset + 1);
  if Index = 0 then
  begin
    if Offset + 1 < Length(Token) then
      Index := Length(Token) + 1 else
      Exit(False); // nothing found
  end;

  Line := Copy(Token, Offset + 1, Index - (Offset + 1));
  Inc(Offset, 2); // Skip Delimiter

  if Line = '' then
  begin // Skip empty lines
    Result := NextLine(Token, Offset, Line);
  end else
  begin
    Inc(Offset, Length(Line));
    Result := True;
  end;
end;

function NativeIntToHex(const Value: NativeInt): string;
const
  {$IFDEF CPUX64}
  MaxHexLength = 16;
  {$ELSE}
  MaxHexLength = 8;
  {$ENDIF}
begin
  Result := IntToHex(Value, MaxHexLength);
end;

function PointerToHex(const Ptr: Pointer): string;
begin
  Result := NativeIntToHex(NativeInt(Ptr));
end;

end.
