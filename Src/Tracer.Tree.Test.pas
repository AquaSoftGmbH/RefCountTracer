unit Tracer.Tree.Test;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface

{$I CheckTestFramework.Inc}

uses
  TestFramework,
  TestFramework.BaseTestCase,
  Tracer.Tree;

type
  TTracerTreeTest = class(TBaseTestCase)
  protected
    Tree: TTracerTree;
  public
    procedure SetUp; override;
    procedure TearDown; override;
    function ToString(const Tree: TTracerTree): string;
  published
    procedure TestParseLog1;
    procedure TestParseLog2;
    procedure TestParseBuildTree1;
    procedure TestParseBuildTree2;
  end;

implementation

uses
  Tracer.Tools,
  System.SysUtils;

{ TTracerTreeTest }

procedure TTracerTreeTest.SetUp;
begin
  Tree := TTracerTree.Create;
end;

procedure TTracerTreeTest.TearDown;
begin
  Tree.Free;
  Tree := nil;
end;

procedure TTracerTreeTest.TestParseBuildTree1;
begin
  Tree.ParseLog(LoadStringFromFile(Fixture('logs\log1.txt')));

  // Build a huge tree with a node for each line in every stack trace
  Tree.BuildTree;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        @IntfCopy'
  + #13#10'          TTracerInterfacedObject._AddRef'
  + #13#10'      Execute'
  + #13#10'        @IntfClear'
  + #13#10'          TTracerInterfacedObject._Release'
  + #13#10, #13#10 + ToString(Tree));

  // Comibine all Nodes with share the same function but have different line numbers and insert nodes for line numbers
  Tree.MergeFunctions;
  Tree.Sort;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        29'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        30'
  + #13#10'          @IntfClear'
  + #13#10'            TTracerInterfacedObject._Release'
  + #13#10, #13#10 + ToString(Tree));

  // Combine all doubled nodes
  Tree.MergeDouble;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        29'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        30'
  + #13#10'          @IntfClear'
  + #13#10'            TTracerInterfacedObject._Release'
  + #13#10, #13#10 + ToString(Tree));
end;

procedure TTracerTreeTest.TestParseBuildTree2;
begin
  Tree.ParseLog(LoadStringFromFile(Fixture('logs\log2.txt')));
  Tree.BuildTree;
  Tree.Sort;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        @IntfCopy'
  + #13#10'          TTracerInterfacedObject._AddRef'
  + #13#10'      Execute'
  + #13#10'        @IntfCopy'
  + #13#10'          TTracerInterfacedObject._AddRef'
  + #13#10'      Execute'
  + #13#10'        @IntfCopy'
  + #13#10'          TTracerInterfacedObject._AddRef'
  + #13#10'      Execute'
  + #13#10'        @IntfCopy'
  + #13#10'          TTracerInterfacedObject._AddRef'
  + #13#10'      Execute'
  + #13#10'        @FinalizeArray'
  + #13#10'          @IntfClear'
  + #13#10'            TTracerInterfacedObject._Release'
  + #13#10'            TTracerInterfacedObject._Release'
  + #13#10, #13#10 + ToString(Tree));

  Tree.MergeFunctions;
  Tree.Sort;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        32'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        33'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        34'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        35'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        36'
  + #13#10'          @FinalizeArray'
  + #13#10'            @IntfClear'
  + #13#10'              TTracerInterfacedObject._Release'
  + #13#10'                50'
  + #13#10'                50'
  + #13#10, #13#10 + ToString(Tree));

  Tree.MergeDouble;
  CheckEquals(''
  + #13#10'root'
  + #13#10'  BaseThreadInitThunk'
  + #13#10'    initialization'
  + #13#10'      Execute'
  + #13#10'        32'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        33'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        34'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        35'
  + #13#10'          @IntfCopy'
  + #13#10'            TTracerInterfacedObject._AddRef'
  + #13#10'        36'
  + #13#10'          @FinalizeArray'
  + #13#10'            @IntfClear'
  + #13#10'              TTracerInterfacedObject._Release'
  + #13#10, #13#10 + ToString(Tree));
end;

procedure TTracerTreeTest.TestParseLog1;
begin
  Tree.ParseLog(LoadStringFromFile(Fixture('logs\log1.txt')));
  CheckEquals(2, Tree.Root.Count);
end;

procedure TTracerTreeTest.TestParseLog2;
begin
  Tree.ParseLog(LoadStringFromFile(Fixture('logs\log2.txt')));
  CheckEquals(6, Tree.Root.Count);
end;

function TTracerTreeTest.ToString(const Tree: TTracerTree): string;
  function Caption(const Node: TTracerTreeNode; const Level: Integer): string;
  begin
    if (Node.Owner <> nil) and (Node.Owner.NodeType = ntFunction) then
      Result := Node.Content[tcLine] else
      Result := Node.Content[tcFunction];

    if Result = '' then
      if Level = 0 then
        Result := 'root' else
        Result := '?';
  end;

  procedure Iterate(const Node: TTracerTreeNode; const Level: Integer);
  var
    i: Integer;
  begin
    Result := Result + ''.PadLeft(Level * 2, ' ') + Caption(Node, Level) + #13#10;
    for i := 0 to Node.Count - 1 do
      Iterate(Node[i], Level + 1); // recursion
  end;
begin
  Result := '';
  Iterate(Tree.Root, 0);
end;

initialization
  RegisterTest(TTracerTreeTest.Suite);
end.
