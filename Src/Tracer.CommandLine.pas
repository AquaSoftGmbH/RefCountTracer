unit Tracer.CommandLine;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 

interface

procedure ExecuteCommandLineInterface;

implementation

uses
  Classes,
  SysUtils,
  Tracer.Tree,
  Tracer.Tools,
  Tracer.Consts,
  Parameters;

type
  TOption = (oRemoveNonLeaked);
  TOptionsSet = set of TOption;
  TOptions = record
    Options: TOptionsSet;
    LogFilename: string;
    GraphFilename: string;
    function ParseParameters: Boolean;
  end;

procedure Error(const ErrorMessageFmt: string; const Values: array of const); overload;
begin
  Writeln('Error: ', Format(ErrorMessageFmt, Values));
  ExitCode := 1;
end;

procedure Error(const ErrorMessage: string); overload;
begin
  Error(ErrorMessage, []);
end;

function CheckFileExists(const Filename: string): Boolean;
begin
  Result := FileExists(Filename);
  if not Result then
    Error('File not found: "%s"', [Filename]);
end;

procedure CheckParam(var TotalResult: Boolean; const ParamResult: Boolean; const ErrorMessage: string);
begin
  TotalResult := TotalResult and ParamResult;
  if not ParamResult then
    Error(ErrorMessage);
end;

function TOptions.ParseParameters: Boolean;
begin
  if not Params then
    Exit(False);

  Result := True;

  Options := [oRemoveNonLeaked];

  LogFilename := GetFileName(1);
  CheckParam(Result, (LogFilename <> '') and CheckFileExists(LogFilename), 'no log file');

  GraphFilename := GetFileName(2);
  if GraphFilename = '' then
    GraphFilename := ChangeFileExt(LogFilename, '.dot');
  CheckParam(Result, (GraphFilename <> ''), 'no output file');

  if Param('l') then
    Exclude(Options, oRemoveNonLeaked);
end;

procedure Syntax;
begin
  WriteLn('RefCountTracer v', ApplicationVersion, ' initiated by AquaSoft GmbH - www.aquasoft.de');
  WriteLn;
  WriteLn('Syntax: RefCountTracer.exe [-l] <Input-LogFilename> [Output-GraphFilename.dot]');
  WriteLn;
  WriteLn('-l DON''T remove not leaking branches from the graph');
  WriteLn;
end;

function LoadLogAsString(const FileName: string): string;
begin
  if not CheckFileExists(Filename) then
    Exit;

  Result := LoadStringFromFile(Filename);
end;

procedure Execute(const Options: TOptions);
var
  Tracer: TTracerTree;
begin
  try
    Tracer := TTracerTree.Create;
    if not Tracer.ParseLog(LoadLogAsString(Options.LogFilename)) then
      Error('Error parsing Log');

    if oRemoveNonLeaked in Options.Options then
      Tracer.RemoveNonLeakedInstances;

    Tracer.BuildTree;
    Tracer.MergeFunctions;

    if oRemoveNonLeaked in Options.Options then
      Tracer.RemoveNonLeaked;

    Tracer.MergeDouble;
    Tracer.MergeSequences;
    Tracer.Root.Sort;

    SaveStringToFile(Options.GraphFilename, Tracer.GenerateDotGraph, True);
  except
    on E: Exception do
      Error(E.Message);
  end;
end;

procedure ExecuteCommandLineInterface;
var
  Options: TOptions;
begin
  if Options.ParseParameters then
    Execute(Options) else
    Syntax;
end;

end.
