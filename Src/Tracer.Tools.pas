unit Tracer.Tools;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface

uses
  SysUtils,
  Classes;

type
  ///	<summary>
  ///	  An additional Encoding-Class which supports writing/reading files as
  ///	  UTF8 but without BOM.
  ///	</summary>
  TUTF8EncodingNoBOM = class(TUTF8Encoding)
  public
    function GetPreamble: TBytes; override;
  end;

procedure ReverseOrder(const List: TStringList);

///	<summary>
///	  Save the contents of a string into a file.
///	</summary>
///	<remarks>
///	  Raises exceptions when file is not found or cannot be read.
///	</remarks>
procedure SaveStringToFile(const FileName: string; const Text: string; const NoUTF8BOM: Boolean);

///	<summary>
///	  Load the contents of a file into a string.
///	</summary>
///	<remarks>
///	  Raises exceptions when file is not found or cannot be read.
///	</remarks>
function LoadStringFromFile(const FileName: string): string;

implementation

{$IFDEF TESTING}
uses
  Tracer.Tools.Test;
{$ENDIF}

{ TUTF8EncodingNoBOM }

function TUTF8EncodingNoBOM.GetPreamble: TBytes;
begin
  SetLength(Result, 0);
end;


{ Procedures & Functions}

function LoadStringFromFile(const FileName: string): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure ReverseOrder(const List: TStringList);
var
  Count, i: Integer;
  Backup: string;
begin
  Count := List.Count - 1;
  for i := 0 to (Count + 1) div 2 - 1 do
  begin
    Backup := List[i];
    List[i] := List[Count - i];
    List[Count - i] := Backup;
  end;
end;

procedure SaveStringToFile(const FileName: string; const Text: string; const NoUTF8BOM: Boolean);
var
  SL: TStringList;
  UTF8NoBOM: TUTF8EncodingNoBOM;
begin
  SL := TStringList.Create;
  try
    SL.Text := Text;
    if NoUTF8BOM then
    begin
      UTF8NoBOM := TUTF8EncodingNoBOM.Create;
      SL.SaveToFile(FileName, UTF8NoBOM);
      UTF8NoBOM.Free;
    end else
    begin
      SL.SaveToFile(FileName, TEncoding.UTF8);
    end;
  finally
    SL.Free;
  end;
end;

end.
