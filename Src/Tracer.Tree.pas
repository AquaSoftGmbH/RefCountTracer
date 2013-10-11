unit Tracer.Tree;

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. 
 
interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  TTraceContentType = (tcAddress, tcModule, tcUnit, tcLine, tcFunction, tcClass);
  TTraceContent = array[TTraceContentType] of string;
  PTraceContent = ^TTraceContent;
  TTraceTreeNodeType = (ntNormal, ntFunction, ntSequence);

  TTracerTreeNode = class(TObjectList<TTracerTreeNode>)
  protected
    class var FUniqueCounter: Integer;
  protected
    FStackTrace: TStringList;
    FReferenceKey: string;
    FLevel: Integer;
    FHits: Integer;
    FContent: TTraceContent;
    FContentParsed: Boolean;
    FFinalRefCount: Integer;
    FRefCountChange: Integer;
    FOwner: TTracerTreeNode;
    FUniqueID: Integer;
    FNodeType: TTraceTreeNodeType;
    function GetCaption: string; virtual;
    function TraceContent(const Line: Integer): TTraceContent;
    procedure SetLevel(const Value: Integer);
    function SortKey: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure MoveTo(const Index: Integer; const TargetNode: TTracerTreeNode);
    function AddHit(const Count: Integer = 1): Integer;
    function IsLeaf: Boolean;
    function ModuleName: string;
    function UnitName: string;
    function GraphKey: string;
    function Content: PTraceContent;
    function ParentRefCount: Integer;
    function ChildrenRefCount: Integer;
    procedure Sort;

    procedure Iterate(const Proc: TProc<TTracerTreeNode>);
    procedure IterateChildren(const Proc: TProc<TTracerTreeNode>);

    ///	<summary>
    ///	  This identifies a specific object instance to be traced.
    ///	</summary>
    property ReferenceKey: string read FReferenceKey write FReferenceKey;
    property StackTrace: TStringList read FStackTrace write FStackTrace;
    property Level: Integer read FLevel write SetLevel;
    property Caption: string read GetCaption;
    property Hits: Integer read FHits;
    property RefCountChange: Integer read FRefCountChange write FRefCountChange;
    property Owner: TTracerTreeNode read FOwner write FOwner;
    property NodeType: TTraceTreeNodeType read FNodeType write FNodeType;
  end;

  TTracerTreeSequenceNode = class(TTracerTreeNode)
  protected
    FSequence: TObjectList<TTracerTreeNode>;
    function GetCaption: string; override;
  public
    constructor Create;
    destructor Destroy; override;

    property Sequence: TObjectList<TTracerTreeNode> read FSequence;
  end;

  TTracerTree = class
  protected
    FRoot: TTracerTreeNode;
    function GetNextToken(var Offset: Integer; const Log: string; out Token: string): Boolean;
    function ParseToken(const Token: string): TTracerTreeNode;
    procedure BuildTree(const List: TTracerTreeNode); overload;
  public
    constructor Create;
    destructor Destroy; override;

    procedure BuildTree; overload;
    ///	<summary>
    ///	  Parse the text based log into a tree, which can be accessed by Root.
    ///	</summary>
    function ParseLog(const Log: string): Boolean;

    ///	<summary>
    ///	  Generates source code to be rendered with Graphviz' dot.
    ///	</summary>
    function GenerateDotGraph: string;

    ///	<summary>
    ///	  Merge alle Nodes without branches to SequenceNodes.
    ///	</summary>
    procedure MergeSequences;

    ///	<summary>
    ///	  Merge all nodes which represents the same function but different
    ///	  linenumbers and insert a node for each linenumber as child nodes.
    ///	</summary>
    procedure MergeFunctions;

    ///	<summary>
    ///	  Merge all remaining doubled entries.
    ///	</summary>
    procedure MergeDouble;

    ///	<summary>
    ///	  Removes all branches which surely do not leak. This can be done for
    ///	  all branches with a RefCount of 0. Only branches with longer living
    ///	  Reference should remain in the tree.
    ///	</summary>
    procedure RemoveNonLeaked;
    procedure Sort;
    property Root: TTracerTreeNode read FRoot;
  end;

implementation

uses
  {$IFDEF TESTING}
  Tracer.Tree.Test,
  {$ENDIF}
  Tracer.Consts,
  Tracer.InternString,
  Tracer.Tools,
  Tracer.Tree.Tools,
  System.Math,
  System.Generics.Defaults, System.StrUtils;

{ TTracerTreeNode }

function TTracerTreeNode.AddHit(const Count: Integer): Integer;
begin
  Inc(FHits, Count);
  Result := FHits;
end;

function TTracerTreeNode.ChildrenRefCount: Integer;
var
  Count: Integer;
begin
  Count := 0;

  IterateChildren(procedure(Node: TTracerTreeNode)
  begin
    Count := Count + Node.RefCountChange;
  end);

  Result := Count;
end;

function TTracerTreeNode.Content: PTraceContent;
begin
  if not FContentParsed then
  begin
    FContent := TraceContent(FLevel);
    FContentParsed := True;
  end;

  Result := @FContent;
end;

constructor TTracerTreeNode.Create;
begin
  inherited Create(True);
  FStackTrace := TStringList.Create;
  FRefCountChange := 0;
  FHits := 1;
  FUniqueID := AtomicIncrement(FUniqueCounter); // generate an unique ID for each Node
  FNodeType := ntNormal;
end;

destructor TTracerTreeNode.Destroy;
begin
  FreeAndNil(FStackTrace);
  inherited;
end;

function TTracerTreeNode.ParentRefCount: Integer;
var
  Node: TTracerTreeNode;
begin
  Result := 0;

  Node := FOwner;
  while Node <> nil do
  begin
    Result := Result + Node.RefCountChange;
    Node := Node.Owner;
  end;
end;

procedure TTracerTreeNode.SetLevel(const Value: Integer);
begin
  FLevel := Value;
  FContentParsed := False;
end;

procedure TTracerTreeNode.Sort;
var
  i: Integer;
begin
  inherited Sort(TComparer<TTracerTreeNode>.Construct(function (const ItemA, ItemB: TTracerTreeNode): Integer
    begin
      Result := CompareText(ItemA.SortKey, ItemB.SortKey);
    end));

  for i := 0 to Count - 1 do
    Items[i].Sort; // recursion
end;

function TTracerTreeNode.SortKey: string;
begin
  Result := Content[tcUnit] + Content[tcClass] + Content[tcFunction] + Content[tcLine].PadLeft(6, '0');
end;

function TTracerTreeNode.GetCaption: string;
var
  _NodeType: TTraceTreeNodeType;
begin
  if FLevel = -1 then
    Result := 'Root' else
  if FLevel < FStackTrace.Count then
    Result := Content[tcFunction] else
    Exit('?');

  if Owner = nil then
    _NodeType := ntNormal else
    _NodeType := Owner.NodeType;

  case _NodeType of
    ntNormal: begin
      Result := Result + '\n' + Format('Refs %d', [ChildrenRefCount]);
      if FRefCountChange <> 0 then
        Result := Result + Format(', Chg %d', [FRefCountChange]);
    end;
    ntFunction: begin
      Result := Content[tcLine];
      Exit;
    end;
  end;
end;

function TTracerTreeNode.GraphKey: string;
begin
  if FLevel = -1 then
    Exit('root');

  Result := Content[tcUnit] + Content[tcFunction] + Content[tcLine];
  Result := Result + '_' + IntToStr(FUniqueID);
  Result := StringReplace(Result, '.', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '@', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '{', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '$', '_', [rfReplaceAll]);
end;

function TTracerTreeNode.IsLeaf: Boolean;
begin
  Result := Count = 0;
end;

procedure TTracerTreeNode.Iterate(const Proc: TProc<TTracerTreeNode>);
begin
  Proc(Self);
  IterateChildren(Proc);
end;

procedure TTracerTreeNode.IterateChildren(const Proc: TProc<TTracerTreeNode>);
  procedure DoIterate(const Node: TTracerTreeNode);
  var
    i: Integer;
  begin
    for i := 0 to Node.Count - 1 do
    begin
      Proc(Node[i]);
      DoIterate(Node[i]); // recursion
    end;
  end;
begin
  DoIterate(Self);
end;

function TTracerTreeNode.ModuleName: string;
begin
  Result := TraceContent(FLevel)[tcModule];
end;

procedure TTracerTreeNode.MoveTo(const Index: Integer; const TargetNode: TTracerTreeNode);
var
  Node: TTracerTreeNode;
begin
  Node := Items[Index];

  // delete it without freeing it
  OwnsObjects := False;
  Delete(Index);
  OwnsObjects := True;

  Node.Level := TargetNode.Level + 1;
  Node.Owner := TargetNode;
  TargetNode.Add(Node);
end;

function TTracerTreeNode.TraceContent(const Line: Integer): TTraceContent;
var
  Entry: string;

  function FromLeft(var s: string; const Delimiter: Char = #9): string;
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

  function FromRight(var s: string; const Delimiter: Char = #9): string;
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
  end;

  function GetClassName(ScopendFunctionName: string): string;
  begin
    if FromRight(ScopendFunctionName, '.') <> '' then // strip function name
      Result := ScopendFunctionName; // rest is the class name
  end;

begin
  if (Line < 0) or (Line >= FStackTrace.Count) then
    Exit;

  Entry := FStackTrace[Line];

  // Sample lines (Tab is the delimiter):
  // 005f267a -> DiaShow.exe -> Vcl.Controls -> 7456 -> TControl.WMMouseMove
  // 74ec8a61 -> user32.dll ->  ->  -> DispatchMessageW

  Result[tcAddress] := FromLeft(Entry);
  Result[tcModule] := FromLeft(Entry);
  Result[tcUnit] := FromLeft(Entry); // can be empty
  Result[tcLine] := FromLeft(Entry); // can be empty
  Result[tcFunction] := FromLeft(Entry);
  Result[tcClass] := GetClassName(Result[tcFunction]);
end;

function TTracerTreeNode.UnitName: string;
begin
  Result := TraceContent(FLevel)[tcUnit];
end;

{ TTracerTreeSequenceNode }

constructor TTracerTreeSequenceNode.Create;
begin
  inherited Create;
  FSequence := TObjectList<TTracerTreeNode>.Create(True);
end;

destructor TTracerTreeSequenceNode.Destroy;
begin
  FreeAndNil(FSequence);
  inherited;
end;

function TTracerTreeSequenceNode.GetCaption: string;
var
  i: Integer;

  function NodeCaption(const Node: TTracerTreeNode): string;
  begin
{    Result := Node.Content[tcClass];
    if Result <> '' then
      Result := Result + '.';}

    Result := '';
    Result := Result + Node.Content[tcFunction];

    Result := StringReplace(Result, '{', '\{', [rfReplaceAll]);
    Result := StringReplace(Result, '}', '\}', [rfReplaceAll]);
    Result := StringReplace(Result, '<', '\<', [rfReplaceAll]);
    Result := StringReplace(Result, '>', '\>', [rfReplaceAll]);
  end;

begin
  Result := '';
  for i := 0 to FSequence.Count - 1 do
  begin
    Result := Result + Format('%s\n', [NodeCaption(FSequence[i])]);
  end;
end;

{ TTracerTree }

procedure TTracerTree.BuildTree(const List: TTracerTreeNode);
var
  i, ii: Integer;
  CurrentChildNode, OtherNode, NewNode: TTracerTreeNode;

  function IsLeaf(const Node: TTracerTreeNode): Boolean;
  begin
    Result := Node.Level >= Node.StackTrace.Count - 1;
  end;

  function CreateIntermediateNode(const Base: TTracerTreeNode): TTracerTreeNode;
  begin
    // Now create an intermediate node to grow the tree
    Result := TTracerTreeNode.Create;
    Result.StackTrace.Assign(Base.StackTrace);
    Result.Level := Base.Level;
    Result.RefCountChange := 0; // only leafs change the refcount
    Result.ReferenceKey := Base.ReferenceKey;
    Result.Owner := Base.Owner;
  end;

begin
  i := 0;
  if List.Count = 0 then
  begin
    if IsLeaf(List) then
      Exit;

    // Successively expand the stacktrace...each line gets a node
    i := List.Owner.IndexOf(List);
    NewNode := CreateIntermediateNode(List);
    List.Owner.Insert(i, NewNode);
    List.Owner.MoveTo(i + 1, NewNode);
    BuildTree(NewNode); // recursion
  end else
  if List.Count = 1 then
  begin
    BuildTree(List[0]); // recursion
  end else
  begin
    while i <= List.Count - 2 do
    begin
      CurrentChildNode := List[i];
      NewNode := nil;
      if not IsLeaf(CurrentChildNode) then
      begin
        for ii := List.Count - 1 downto i + 1 do
        begin
          OtherNode := List[ii];
          if IsSameTraceAtLevel(CurrentChildNode, OtherNode, CurrentChildNode.Level) then
          begin
            if not IsLeaf(OtherNode) then
            begin // we found a node with a common ancestor.
              if NewNode = nil then
              begin
                // Now create an intermediate node to grow the tree
                NewNode := CreateIntermediateNode(CurrentChildNode);
              end;

              // Move "OtherNode" to intermediate node as a child
              List.MoveTo(ii, NewNode);
              NewNode.AddHit(OtherNode.Hits);
            end;
          end;
        end;
        if NewNode <> nil then
        begin
          // Insert intermediate node into the tree
          List.Insert(i, NewNode);
          List.MoveTo(i + 1, NewNode); // Move CurrentChildNode to the intermediate node
        end;
      end;

      Inc(i);
    end;

    for i := 0 to List.Count - 1 do
      BuildTree(List[i]); // recursion
  end;
end;

procedure TTracerTree.BuildTree;
begin
  BuildTree(FRoot);
end;

constructor TTracerTree.Create;
begin
  inherited;

  FRoot := TTracerTreeNode.Create;
  FRoot.Level := -1;
end;

destructor TTracerTree.Destroy;
begin
  FreeAndNil(FRoot);

  inherited;
end;

function TTracerTree.GenerateDotGraph: string;
var
  SourceCode: TStringBuilder;

  function RenderNode(const Parent, Node: TTracerTreeNode): string;
  var
    Options: string;
  begin
    if Parent <> nil then
      Result := Parent.GraphKey;

    if Result <> '' then
      Result := Result + ' -> ';
    Result := Result + Node.GraphKey;

    // Edge Options
    Options := '';

    if Node.Hits > 1 then
    begin
      Options := Options + Format('penwidth=%d;', [Round(Max(1, Min(20, Node.Hits * 0.25)))]);
      Options := Options + Format('label="%dx";', [Node.Hits]);
    end;

    if (Parent <> nil) and (Parent.NodeType = ntFunction) then
      Options := Options + Format('weight=400;', []);

    if Options <> '' then
      Result := Result + '[' + Options + ']';

  end;

  ///	<summary>
  ///	  Generates one line of source code for each leaf of the tree.
  ///	</summary>
  function NodeGraph(const Base: string; const Node: TTracerTreeNode): string;
  var
    i: Integer;
  begin
    if Node.IsLeaf then
    begin // no child nodes
      SourceCode.AppendLine(#9 + Result);
    end else
    for i := 0 to Node.Count - 1 do
    begin
      SourceCode.AppendLine(#9 + RenderNode(Node, Node[i]));
    end;

    // recurse after all childs are drawn, this helps graphviz zu align direct neighbours
    for i := 0 to Node.Count - 1 do
    begin
      NodeGraph('', Node[i]); // recursion
    end;
  end;

  procedure AddNodeCaptions;

    procedure Iterate(const Node: TTracerTreeNode);
    var
      i: Integer;
    begin
      SourceCode.AppendFormat('%s[label="%s"', [Node.GraphKey, Node.Caption]);
      if Node.IsLeaf then
      begin
        SourceCode.Append('style=filled;');
        if Node.RefCountChange < 0 then
          SourceCode.Append('color=green;') else
        if Node.RefCountChange > 0 then
          SourceCode.Append('color=red;');
      end;

      if Node is TTracerTreeSequenceNode then
        SourceCode.Append('shape=record;');

      // Add more informationen about the node as a Tooltip
      SourceCode.AppendFormat('tooltip="Unit: %s, Class: %s, Function: %s, Line:%s";', [Node.Content[tcUnit], Node.Content[tcClass], Node.Content[tcFunction], Node.Content[tcLine]]);

      SourceCode.Append('];');
      SourceCode.AppendLine;

      for i := 0 to Node.Count - 1 do
        Iterate(Node[i]); // recursion
    end;

  begin
    Iterate(Root);
  end;

  procedure AddCluster(const ClusterType, ClusterTypeFallback: TTraceContentType);
  var
    ClusterMap: TObjectDictionary<string, TStringList>;

    procedure Iterate(const Node: TTracerTreeNode);
    var
      ClusterName: string;
      i: Integer;
      List: TStringList;
    begin
      ClusterName := Node.Content[ClusterType];
      if ClusterName = '' then
        ClusterName := Node.Content[ClusterTypeFallback];


      if ClusterName <> '' then
      begin
        if not ClusterMap.TryGetValue(ClusterName, List) then
        begin
          List := TStringList.Create;
          List.CaseSensitive := True;
          List.Sorted := True;
          List.Duplicates := dupIgnore;
          ClusterMap.Add(ClusterName, List);
        end;
        List.Add(Node.GraphKey);
      end;

      for i := 0 to Node.Count - 1 do
        Iterate(Node[i]); // recursion
    end;

    procedure GenerateCode;
    var
      Pair: TPair<string, TStringList>;
      i, Count: Integer;
    begin
      Count := 0;
      for Pair in ClusterMap do
      begin
        SourceCode.AppendFormat('subgraph cluster%d {', [Count]);
        SourceCode.AppendLine(Format('label="%s";', [Pair.Key]));
        SourceCode.AppendLine(Format('style=filled;', []));
        SourceCode.AppendLine(Format('color=lightgray;', []));
        for i := 0 to Pair.Value.Count - 1 do
          SourceCode.AppendLine(Pair.Value[i]);

        SourceCode.AppendLine('}');
        Inc(Count);
      end;
    end;
  begin
    ClusterMap := TObjectDictionary<string, TStringList>.Create([doOwnsValues]);

    Iterate(Root);
    GenerateCode;

    ClusterMap.Free;
  end;
begin
  SourceCode := TStringBuilder.Create;
  SourceCode.AppendLine('strict digraph G {');
  AddNodeCaptions;
//  AddCluster(tcModule, tcModule);
//  AddCluster(tcUnit, tcModule);
//  AddCluster(tcClass, tcUnit);
  NodeGraph('', Root);
  SourceCode.AppendLine('}');

  Result := SourceCode.ToString;
end;

function TTracerTree.GetNextToken(var Offset: Integer; const Log: string; out Token: string): Boolean;
var
  Index: Integer;
begin
  Index := Pos(TraceLogDelimiter, Log, Offset + 1);
  if Index = 0 then
  begin
    if Offset < Length(Log) then
    begin // last log entry
      Index := Length(Log);
    end else
    begin // Already at the end of the log
      Exit(False);
    end;
  end;

  Result := True;
  Token := Copy(Log, Offset + 1, Index - Offset - 1);
  Inc(Offset, Length(TraceLogDelimiter));
  Inc(Offset, Length(Token));
end;

procedure TTracerTree.MergeDouble;
  procedure RemoveOrphans(const Orphan, Parent: TTracerTreeNode);
  begin
    // Removes orphaned line number nodes
	
    // Check if it is an orphan. This is the case if:
    // 1. Parent is NodeType = ntFunction
    // 2. Node is the one and only child of Parent

    // Check 1.
    if Parent.NodeType <> ntFunction then
      Exit;

    // Check 2.1.
    if not Orphan.IsLeaf then
      Exit;

    // Check 2.2.
    if (Parent.Count <> 1) then
      Exit;

    // Convert Parent into a normal Node
    Parent.NodeType := ntNormal;
    Parent.RefCountChange := Parent.RefCountChange + Orphan.RefCountChange;
    Parent.Remove(Orphan);
  end;

  procedure Iterate(const List: TTracerTreeNode);
  var
    i: Integer;
    Node: TTracerTreeNode;
  begin
    i := 0;
    while i <= List.Count - 2 do
    begin
      Node := List[i];
      if IsSameTrace(Node, List[i + 1]) then
      begin
        MergeNodes(Node, List[i + 1]);
        RemoveOrphans(Node, List);
      end else
        Inc(i);
    end;

    for i := 0 to List.Count - 1 do
      Iterate(List[i]); // recursion
  end;
begin
  Sort;
  Iterate(Root);
end;

procedure TTracerTree.MergeFunctions;
  function IsSameFunction(const Node1, Node2: TTracerTreeNode): Boolean;
  begin
    Result :=
     (Node1.Content[tcModule] = Node2.Content[tcModule]) and
     (Node1.Content[tcUnit] = Node2.Content[tcUnit]) and
     (Node1.Content[tcClass] = Node2.Content[tcClass]) and
     (Node1.Content[tcFunction] = Node2.Content[tcFunction])and
     (Node1.Content[tcLine] <> '') and
     (Node2.Content[tcLine] <> '') and
     (Node1.IsLeaf = Node2.IsLeaf);
  end;

  function CreateIntermediateNode(const Base: TTracerTreeNode): TTracerTreeNode;
  begin
    // Now create an intermediate node to grow the tree
    Result := TTracerTreeNode.Create;
    Result.StackTrace.Assign(Base.StackTrace);
    Result.Level := Base.Level;
    Result.RefCountChange := 0; // only leafs change the refcount
    Result.ReferenceKey := Base.ReferenceKey;
    Result.Owner := Base.Owner;
    Result.AddHit(Base.Hits);
    Result.NodeType := ntFunction;
  end;

  procedure Iterate(const List: TTracerTreeNode);
  var
    i, ii: Integer;
    Node1, Node2: TTracerTreeNode;
    NewNode: TTracerTreeNode;
  begin
    if List.NodeType <> ntFunction then
    begin
      i := 0;
      while i <= List.Count - 2 do
      begin
        Node1 := List[i];
        NewNode := nil;
        for ii := List.Count - 1 downto i + 1 do
        begin
          Node2 := List[ii];
          if IsSameFunction(Node1, Node2) then
          begin // create a common node for the function, with a subnode for each code line number
            if NewNode = nil then
              NewNode := CreateIntermediateNode(Node1);

            // Move "Node2" to intermediate node as a child
            List.MoveTo(ii, NewNode);
            Node2.Level := Node1.Level;
            NewNode.AddHit(Node2.Hits);
          end;
        end;
        if NewNode <> nil then
        begin
          // Insert intermediate node into the tree
          List.Insert(i, NewNode);
          List.MoveTo(i + 1, NewNode); // Move Node1 to the intermediate node
          Node1.Level := NewNode.Level;
        end;

        Inc(i);
      end;
    end;

    for i := 0 to List.Count - 1 do
      Iterate(List[i]); // recursion
  end;

begin
  Sort;

  Iterate(FRoot);
end;

procedure TTracerTree.MergeSequences;

  function CreateSequenceNode(const Base: TTracerTreeNode): TTracerTreeSequenceNode;
  var
    Index: Integer;
    Child: TTracerTreeNode;
  begin
    Assert(Base.Owner <> nil);

    Result := TTracerTreeSequenceNode.Create;
    Index := Base.Owner.IndexOf(Base);

    Result.Owner := Base.Owner;
    Result.AddHit(Base.Hits);
    Base.Owner.Insert(Index, Result);

    // Base is now the first item in the sequence
    Base.Owner.Extract(Base);
    Result.Sequence.Add(Base);

    // reattach child from base to the sequence node
    Child := Base.First;
    Base.Extract(Child);
    Result.Add(Child);
  end;

  procedure Iterate(List: TTracerTreeNode);
  var
    i: Integer;
    SequenceNode: TTracerTreeSequenceNode;
    Node, Child: TTracerTreeNode;
  begin
    // Two Nodes without branches follow each other?
    if (List.Owner <> nil) and (List.Count = 1) and (List.Owner.NodeType <> ntFunction) then
    begin
      Node := List[0]; // the one and only child node
      if Node.Count = 1 then
      begin
        if List is TTracerTreeSequenceNode then
        begin
          SequenceNode := List as TTracerTreeSequenceNode;
          List.Extract(Node);
          SequenceNode.Sequence.Add(Node);

          // reattach child to the sequence node
          Child := Node.First;
          Node.Extract(Child);
          SequenceNode.Add(Child);
        end else
        begin
          SequenceNode := CreateSequenceNode(List);
        end;
        Iterate(SequenceNode); // recursion
        Exit;
      end;
    end;

    for i := 0 to List.Count - 1 do
      Iterate(List[i]); // recursion
  end;
begin
  Iterate(Root);
end;

function TTracerTree.ParseLog(const Log: string): Boolean;
var
  Offset: Integer;
  Token: string;
  Node: TTracerTreeNode;
begin
  // Todo: Refactor out the parsing code to make it plugable and support more
  // stack trace formats (MadExcept, JCL, Eurekalog)

  FRoot.Clear;

  // Create a flat list of all log entries
  Offset := 0;
  while GetNextToken(Offset, Log, Token) do
  begin
    Node := ParseToken(Token);
    if Node <> nil then
      FRoot.Add(Node);
  end;

  // Hint: to build a tree from that list call BuildTree

  Result := FRoot.Count > 0;
end;

function TTracerTree.ParseToken(const Token: string): TTracerTreeNode;
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

  function NextLine(var Offset: Integer; out Line: string): Boolean;
  var
    Index: Integer;
  begin
    Index := Pos(#13#10, Token, Offset + 1);
    if Index = 0 then
    begin
      if Offset + 1 < Length(Token) then
        Index := Length(Token) else
        Exit(False); // nothing found
    end;

    Line := Copy(Token, Offset + 1, Index - (Offset + 1));
    Inc(Offset, 2); // Skip Delimiter

    if Line = '' then
    begin // Skip empty lines
      Result := NextLine(Offset, Line);
    end else
    begin
      Inc(Offset, Length(Line));
      Line := TrimWhiteSpace(Line);
      Line := InternString(Line); // Save Memory
      Result := True;
    end;
  end;
var
  Line: string;
  Offset, Value: Integer;
begin
  Result := nil;
  if Token = '' then
    Exit;
  Offset := 0;

  if not NextLine(Offset, Line) then
    Exit;
  Result := TTracerTreeNode.Create;
  Result.Owner := FRoot;

  Result.ReferenceKey := Line; // first line contains the key

  if not NextLine(Offset, Line) then
    Exit;
  // Secod line contains RefCountChange
  System.Delete(Line, 1, Length('refcountchange: '));
  if not TryStrToInt(Line, Value) then
  begin
    FreeAndNil(Result);
    Exit;
  end;
  Result.RefCountChange := Value;

  // Parse all lines from the stacktrace
  while NextLine(Offset, Line) do
    Result.StackTrace.Add(Line);

  ReverseOrder(Result.StackTrace);
end;

procedure TTracerTree.RemoveNonLeaked;
  procedure DoIterate(const Node: TTracerTreeNode);
  var
    i: Integer;
  begin
    for i := Node.Count - 1 downto 0 do
    begin
      if (Node[i].ChildrenRefCount) + (Node[i].RefCountChange) = 0 then
        Node.Delete(i) else
        DoIterate(Node[i]); // recursion
    end;
  end;
begin
  DoIterate(Root);
end;

procedure TTracerTree.Sort;
begin
  FRoot.Sort;
end;

initialization
finalization
end.
