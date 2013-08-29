unit Tracer.Tree.Tools;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

uses
  Tracer.Tree;

function IsSameTraceAtLevel(const NodeA, NodeB: TTracerTreeNode; const Level: Integer): Boolean;
function IsSameTrace(const NodeA, NodeB: TTracerTreeNode): Boolean;
procedure MergeNodes(const NodeA, NodeB: TTracerTreeNode);

implementation

function IsSameTraceAtLevel(const NodeA, NodeB: TTracerTreeNode; const Level: Integer): Boolean;
var
  TraceA, TraceB: string;
begin
  TraceA := '';
  TraceB := '';
  if NodeA.StackTrace.Count > Level then
    TraceA := NodeA.StackTrace[Level];
  if NodeB.StackTrace.Count > Level then
    TraceB := NodeB.StackTrace[Level];

  Result := TraceA = TraceB;
end;

function IsSameTrace(const NodeA, NodeB: TTracerTreeNode): Boolean;
begin
  Result :=
    (NodeA.Level = NodeB.Level) and
    (NodeA.Content[tcLine] = NodeB.Content[tcLine]) and
    (NodeA.Content[tcFunction] = NodeB.Content[tcFunction]) and
    (NodeA.Content[tcClass] = NodeB.Content[tcClass]) and
    (NodeA.Content[tcUnit] = NodeB.Content[tcUnit]) and
    (NodeA.Content[tcModule] = NodeB.Content[tcModule]) and
    (NodeA.IsLeaf = NodeB.IsLeaf);
end;

procedure MergeNodes(const NodeA, NodeB: TTracerTreeNode);
var
  i: Integer;
  Child: TTracerTreeNode;
begin
  NodeB.Owner.Extract(NodeB);

  // move children from NodeB to NodeA
  NodeB.OwnsObjects := False;
  for i := 0 to NodeB.Count - 1 do
  begin
    Child := NodeB[i];
    Child.Owner := NodeA;
    NodeA.Add(Child);
  end;

  // combine values
  NodeA.AddHit(NodeB.Hits);
  NodeA.RefCountChange := NodeA.RefCountChange + NodeB.RefCountChange;

  // free the now unneeded node
  NodeB.Free;
end;

end.
