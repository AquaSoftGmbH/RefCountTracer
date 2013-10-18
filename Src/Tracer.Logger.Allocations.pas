unit Tracer.Logger.Allocations;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,
  WinApi.Windows;

type
  ///	<summary>
  ///	  Base class for logging allocations and deallocations of T (Objects,
  ///	  Handles, Whatever)
  ///	</summary>
  TAllocationLogger<T> = class
  protected
    type
      TAllocationLog = TDictionary<T, Integer>;
  protected
    FAllocations: TAllocationLog;
    FAllocationCounter: Integer;
    FLock: TCriticalSection;
    function IncAllocationCount: Integer;
    procedure OutputLeaks;
    function FormatLeak(const Allocation: T; const AllocationOrder: Integer): string; virtual; abstract;
    procedure WriteDebug(const s: string); overload;
    procedure WriteDebug(const Format: string; const Values: array of const); overload;
    procedure AlreadyAllocated(const Allocation: T; const AllocationOrder: Integer); virtual;
    procedure Allocated(const Allocation: T; const AllocationOrder: Integer); virtual;
    procedure DeAllocated(const Allocation: T; const AllocationOrder: Integer); virtual;
    procedure AllocationNotFound(const Allocation: T); virtual;
    procedure AllocationUsed(const Allocation: T; const AllocationOrder: Integer); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function LogCreate(const Allocation: T): Integer;
    function LogDestroy(const Allocation: T): Integer;
    function LogUse(const Allocation: T): Integer;
    function AllocationNr(const Allocation: T): Integer;
  end;

  ///	<summary>
  ///	  A Logger for (De)Allocations of Handles
  ///	</summary>
  THandleAllocationLogger = class(TAllocationLogger<THandle>)
  protected
    FHandleTypes: TDictionary<THandle, DWORD>;
    function HandleTypeName(const HandleType: DWORD): string;
    function HandleType(const Handle: THandle): DWORD;
    function FormatLeak(const Allocation: THandle; const AllocationOrder: Integer): string; override;
    procedure Allocated(const Allocation: THandle; const AllocationOrder: Integer); override;
    procedure DeAllocated(const Allocation: THandle; const AllocationOrder: Integer); virtual;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  ///	<summary>
  ///	  A Logger for (De)Allocations of Objectreferences
  ///	</summary>
  TObjectAllocationLogger = class(TAllocationLogger<TObject>)
  protected
    function FormatLeak(const Allocation: TObject; const AllocationOrder: Integer): string; override;
    procedure AlreadyAllocated(const Allocation: TObject; const AllocationOrder: Integer); override;
    procedure Allocated(const Allocation: TObject; const AllocationOrder: Integer); override;
    procedure DeAllocated(const Allocation: TObject; const AllocationOrder: Integer); override;
    procedure AllocationNotFound(const Allocation: TObject); override;
    procedure AllocationUsed(const Allocation: TObject; const AllocationOrder: Integer); override;
  end;

  TObjectLoggerHelper = class helper for TObject
    function LogCreate: Integer;
    function LogDestroy: Integer;
    function LogUse: Integer;
    function AllocationNr: Integer;
  end;

function ObjectLogger: TObjectAllocationLogger;
function HandleLogger: THandleAllocationLogger;

implementation

uses
  System.Classes,
  System.SysUtils,
  SingletonImp, Tracer.Logger.Tools;

type
  TObjectAllocationLoggerSingleton = TSingleton<TObjectAllocationLogger>;
  THandleAllocationLoggerSingleton = TSingleton<THandleAllocationLogger>;

function ObjectLogger: TObjectAllocationLogger;
begin
  Result := TObjectAllocationLoggerSingleton.Instance;
end;

function HandleLogger: THandleAllocationLogger;
begin
  Result := THandleAllocationLoggerSingleton.Instance;
end;

procedure TAllocationLogger<T>.AlreadyAllocated(const Allocation: T;
  const AllocationOrder: Integer);
begin
  // free for derived classes
end;

constructor TAllocationLogger<T>.Create;
begin
  FAllocations := TAllocationLog.Create;
  FAllocationCounter := 0;
  FLock := TCriticalSection.Create;
end;

procedure TAllocationLogger<T>.DeAllocated(const Allocation: T;
  const AllocationOrder: Integer);
begin
  // free for derived classes
end;

destructor TAllocationLogger<T>.Destroy;
begin
  OutputLeaks;
  FreeAndNil(FAllocations);
  FreeAndNil(FLock);
  WriteDebug('ClassLogger destroyed. Calls to LogDestroy are unpredictable now.');
end;

function TAllocationLogger<T>.IncAllocationCount: Integer;
begin
  Result := AtomicIncrement(FAllocationCounter);
end;

function TAllocationLogger<T>.LogCreate(const Allocation: T): Integer;
begin
  FLock.Enter;
  try
    if FAllocations.TryGetValue(Allocation, Result) then
    begin
      AlreadyAllocated(Allocation, Result);
    end else
    begin
      Result := IncAllocationCount;
      FAllocations.Add(Allocation, Result);
      Allocated(Allocation, Result);
    end;
  finally
    FLock.Leave;
  end;
end;

function TAllocationLogger<T>.LogDestroy(const Allocation: T): Integer;
begin
  FLock.Enter;
  try
    if (FAllocations <> nil) and FAllocations.TryGetValue(Allocation, Result) then
    begin
      DeAllocated(Allocation, Result);
      FAllocations.Remove(Allocation);
    end else
    begin
      Result := -1;
      AllocationNotFound(Allocation);
    end;
  finally
    FLock.Leave;
  end;
end;

function TAllocationLogger<T>.LogUse(const Allocation: T): Integer;
begin
  FLock.Enter;
  try
    if (FAllocations <> nil) and FAllocations.TryGetValue(Allocation, Result) then
    begin
      AllocationUsed(Allocation, Result);
    end else
    begin
      Result := -1;
      AllocationNotFound(Allocation);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TAllocationLogger<T>.OutputLeaks;
var
  Allocation: T;
  Sort: TStringList;
  s: string;
begin
  inherited;

  Sort := TStringList.Create;

  for Allocation in FAllocations.Keys do
    Sort.Add(FormatLeak(Allocation, FAllocations[Allocation]));

  Sort.Sort;

  for s in Sort do
    WriteDebug(s);

  Sort.Free;
end;

procedure TAllocationLogger<T>.WriteDebug(const s: string);
begin
  OutputDebugString(PChar(s));
end;

procedure TAllocationLogger<T>.WriteDebug(const Format: string;
  const Values: array of const);
begin
  WriteDebug(System.SysUtils.Format(Format, Values));
end;

procedure TAllocationLogger<T>.Allocated(const Allocation: T;
  const AllocationOrder: Integer);
begin
  // free for derived classes
end;

procedure TAllocationLogger<T>.AllocationNotFound(const Allocation: T);
begin
//  WriteDebug('Instance not found! Already Freed? Or LogCreate not called? Or AllocationLogger already destroyed?');
end;

function TAllocationLogger<T>.AllocationNr(const Allocation: T): Integer;
begin
  if not FAllocations.TryGetValue(Allocation, Result) then
    Result := -1;
end;

procedure TAllocationLogger<T>.AllocationUsed(const Allocation: T;
  const AllocationOrder: Integer);
begin
  // free for derived classes
end;

{ TObjectLoggerHelper }

function TObjectLoggerHelper.LogCreate: Integer;
begin
  Result := ObjectLogger.LogCreate(Self);
end;

function TObjectLoggerHelper.LogDestroy: Integer;
begin
  Result := ObjectLogger.LogDestroy(Self);
end;

function TObjectLoggerHelper.LogUse: Integer;
begin
  Result := ObjectLogger.LogUse(Self);
end;

function TObjectLoggerHelper.AllocationNr: Integer;
begin
  Result := ObjectLogger.AllocationNr(Self);
end;

{ TObjectAllocationLogger }

procedure TObjectAllocationLogger.Allocated(const Allocation: TObject;
  const AllocationOrder: Integer);
begin
  inherited;
  WriteDebug('Instance %s.%s allocated, Allocation Order: %d', [Allocation.UnitName, Allocation.Classname, AllocationOrder]);
end;

procedure TObjectAllocationLogger.AllocationNotFound(const Allocation: TObject);
begin
  inherited;
  WriteDebug('Instance %s.%s', [Allocation.UnitName, Allocation.Classname]);
end;

procedure TObjectAllocationLogger.AllocationUsed(const Allocation: TObject;
  const AllocationOrder: Integer);
begin
  inherited;
  WriteDebug('Instance %s.%s used, Allocation Order: %d', [Allocation.UnitName, Allocation.Classname, AllocationOrder]);
end;

procedure TObjectAllocationLogger.AlreadyAllocated(const Allocation: TObject;
  const AllocationOrder: Integer);
begin
  inherited;
  WriteDebug('Instance %s.%s already allocated, Allocation Order: %d', [Allocation.UnitName, Allocation.Classname, AllocationOrder]);
end;

procedure TObjectAllocationLogger.DeAllocated(const Allocation: TObject;
  const AllocationOrder: Integer);
begin
  inherited;
  WriteDebug('Instance %s.%s destroyed, Allocation Order: %d', [Allocation.UnitName, Allocation.Classname, AllocationOrder]);
end;

function TObjectAllocationLogger.FormatLeak(const Allocation: TObject;
  const AllocationOrder: Integer): string;

  function GetRefCount(const Allocation: TObject): string;
  begin
    Result := 'Unknown';
    if Allocation is TInterfacedObject then
      Result := IntToStr(TInterfacedObject(Allocation).RefCount);
{    if Allocation is TInterfaceImp then
      Result := IntToStr(TInterfaceImp(Allocation).RefCount);}
  end;

begin
  Result := Format('Memory Leak: Instance %s.%s, Allocation Order: %d, RefCount: %s', [Allocation.UnitName, Allocation.ClassName, AllocationOrder, GetRefCount(Allocation)]);
end;

{ THandleAllocationLogger }

procedure THandleAllocationLogger.Allocated(const Allocation: THandle;
  const AllocationOrder: Integer);
begin
  inherited;
  FHandleTypes.AddOrSetValue(Allocation, HandleType(Allocation));
end;

constructor THandleAllocationLogger.Create;
begin
  inherited Create;
  FHandleTypes := TDictionary<THandle, DWORD>.Create;
end;

procedure THandleAllocationLogger.DeAllocated(const Allocation: THandle;
  const AllocationOrder: Integer);
begin
  FHandleTypes.Remove(Allocation);
end;

destructor THandleAllocationLogger.Destroy;
begin
  inherited;
  FreeAndNil(FHandleTypes);
end;

function THandleAllocationLogger.FormatLeak(const Allocation: THandle;
  const AllocationOrder: Integer): string;
  function GetHandleType: string;
  var
    HandleType: DWORD;
  begin
    if not FHandleTypes.TryGetValue(Allocation, HandleType) then
      HandleType := 0;

    Result := HandleTypeName(HandleType);
  end;
begin
  Result := Format('Handle Leak: %s, Allocation Order: %d, Handle $%s', [GetHandleType, AllocationOrder, NativeIntToHex(Allocation)]);
end;


function THandleAllocationLogger.HandleType(const Handle: THandle): DWORD;
begin
  Result := GetObjectType(Handle);
end;

function THandleAllocationLogger.HandleTypeName(
  const HandleType: DWORD): string;
const
  OBJ_COLORSPACE = 14; // Missing Deklaration in Winapi.Windows.pas
begin
  case HandleType of
    OBJ_BITMAP: Result := 'Bitmap';
    OBJ_BRUSH: Result := 'Brush';
    OBJ_COLORSPACE: Result := 'Color space';
    OBJ_DC: Result := 'Device context';
    OBJ_ENHMETADC: Result := 'Enhanced metafile DC';
    OBJ_ENHMETAFILE: Result := 'Enhanced metafile';
    OBJ_EXTPEN: Result := 'Extended pen';
    OBJ_FONT: Result := 'Font';
    OBJ_MEMDC: Result := 'Memory DC';
    OBJ_METAFILE: Result := 'Metafile';
    OBJ_METADC: Result := 'Metafile DC';
    OBJ_PAL: Result := 'Palette';
    OBJ_PEN: Result := 'Pen';
    OBJ_REGION: Result := 'Region';
    else Result := 'Unknown';
  end;
end;

end.
