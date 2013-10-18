unit Tracer.Logger.MadExcept;

interface

uses
  Tracer.Logger;

type
  TMadExceptRefCountTracerLog = class(TRefCountTracerLog)
  protected
    procedure LogLine(Line: string);
    procedure DoLogStackTrace; override;
  end;

implementation

uses
  SysUtils,
  MadStackTrace,
  Tracer.Logger.Tools;

{ TMadExceptRefCountTracerLog }

procedure TMadExceptRefCountTracerLog.DoLogStackTrace;
const
  Skip = 2; // Skip the unneeded Lines in the call stack (TMadExceptRefCountTracerLog.DoLogStackTrace and its base class (TRefCountTracerLog.DoLogStackTrace))
var
  Trace, Line: string;
  Offset, Count: Integer;
begin
  Trace := StackTrace;
  Offset := 0;
  Count := 0;
  while NextLine(Trace, Offset, Line) do
  begin
    Inc(Count);
    if Count > Skip then
      LogLine(Line);
  end;
end;

procedure TMadExceptRefCountTracerLog.LogLine(Line: string);

  function TrimWhiteSpace(const s: string): string;
  var
    L: Integer;
  begin
    Result := s;
    repeat
      L := Length(Result);
      Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]); // Replace double white space with single whitespace
    until L = Length(Result); // until no change in length anymore
  end;

  function FromLeft(var s: string; const Delimiter: Char = ' '): string;
  var
    Index: Integer;
  begin
    Index := Pos(Delimiter, s);
    if Index = 0 then
    begin
      Result := s;
      s := '';
    end else
    begin
      Result := Copy(s, 1, Index);
      System.Delete(s, 1, Index);
    end;
    Result := Trim(Result);
  end;

  function FromRight(var s: string; const Delimiter: Char = ' '): string;
  var
    Index: Integer;
  begin
    for Index := Length(s) downto 1 do
    begin
      if s[Index] = Delimiter then
      begin
        Result := Copy(s, Index + 1, Length(s) - Index);
        System.Delete(s, Index, Length(s) - Index + 1);
        Result := Trim(Result);

        Exit;
      end;
    end;

    Result := Trim(s);
    s := '';
  end;

var
  Entry: TStackTraceEntry;

begin
  // Sample lines:
  // 005f267a DiaShow.exe  Vcl.Controls                                 7456 TControl.WMMouseMove
  // 74ec8a61 user32.dll                                                     DispatchMessageW

  Line := TrimWhiteSpace(Line);
  Entry.Address := FromLeft(Line);
  Entry.Module := FromLeft(Line);
  Entry.FunctionName := FromRight(Line);
  Entry.Line := FromRight(Line); // can be empty
  Entry.UnitName := Trim(Line); // can be empty

  AddStackTraceEntry(Entry);
end;

initialization
  RegisterStackTracer(TMadExceptRefCountTracerLog);
end.
