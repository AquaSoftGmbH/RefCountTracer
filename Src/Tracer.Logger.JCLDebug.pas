unit Tracer.Logger.JCLDebug;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 

interface

uses
  Tracer.Logger;

type
  TJCLDebugRefCountTracerLog = class(TRefCountTracerLog)
    // Todo: Implement
  end;

implementation

initialization
  RegisterStackTracer(TJCLDebugRefCountTracerLog);
end.
