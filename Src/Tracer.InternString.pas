unit Tracer.InternString;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

function InternString(const Value: string): string;

implementation

uses
  System.Generics.Collections;

var
  Strings: TDictionary<string, string>;
  CacheHit: Integer = 0;
  CacheMiss: Integer = 0;

function InternString(const Value: string): string;
begin
  if Strings.TryGetValue(Value, Result) then
  begin
    Inc(CacheHit);
    Exit;
  end;

  Result := Value;
  Strings.Add(Value, Value);
  Inc(CacheMiss);
end;

initialization
  Strings := TDictionary<string, string>.Create;
finalization
  Strings.Free;
end.
