unit ConsVarsTypes;

interface
uses SysUtils, Windows, Messages, TlHelp32;

type
   // Helper class for ToolHelp functions
  TToolHelper = class(TObject)
  private
    FHSnapshot: THandle;
    procedure CreateSnapshot(cFlags, cProcessID: Cardinal);
    procedure DestroySnapshot;
  public
    constructor Create(cFlags: Cardinal; cProcessID: Cardinal = 0);
    destructor  Destroy; override;
     // Process enumeration
    function  ProcessFirst(var pe: TProcessEntry32): Boolean;
    function  ProcessNext(var pe: TProcessEntry32): Boolean;
//    function  ProcessFind(cProcessID: Cardinal; var pe: TProcessEntry32): Boolean;
     // Module enumeration
    function  ModuleFirst(var me: TModuleEntry32): Boolean;
    function  ModuleNext(var me: TModuleEntry32): Boolean;
  end;

  TPopulateMethod = procedure of object;

   // ListView sort mode/population specifier
  PListViewSort = ^TListViewSort;
  TListViewSort = record
    iColIndex: Integer; // Column by which ListView is sorted
    bSortDesc: Boolean; // True if ListView is sorted in reverse (descending) order
  end;

const
   // Image indices
  iiiProcess              = 0;
  iiiLibrary              = 1;
  iiiExit                 = 2;
  iiiAbout                = 3;
  iiiRefresh              = 4;
  iiiAutoRefresh          = 5;
  iiiUp                   = 6;
  iiiDown                 = 7;

  SRegKey_Main            = 'Software\DaleTech\ProcessExplorer';
  SRegKey_Toolbars        = SRegKey_Main+'\Toolbars';
  SRegSection_Preferences = 'Preferences';

   // Sort image indicator selector: [bCurrentCol, bDescending]
  aiiiSort: Array[Boolean, Boolean] of Integer = ((-1, -1), (iiiUp, iiiDown));

resourcestring
  SMsg_AboutText       =
    'ProcessExplorer v0.02'#13+
    'Copyright ©2003 Dmitry Kann/Dale, http://devtools.narod.ru'#13+
    'Based on an original idea of Jeffrey Richter, www.jeffreyrichter.com';
  SMsg_AboutTitle      = 'About ProcessExplorer';
  SProcessDetailFormat =
    'Executable file name: %s'#13+
    'Process ID: %.8x'#13+
    'Parent process ID: %.8x'#13+
    'Priority class: %d'#13+
    'Threads: %d'#13+
    #13+
    'Modules information:';
  SModuleFixed         = 'Fixed';


   // Returns preferred address for the module
  function GetModulePreferredBaseAddr(cProcessID: Cardinal; pBaseAddr: Pointer): Cardinal;

implementation

  function GetModulePreferredBaseAddr(cProcessID: Cardinal; pBaseAddr: Pointer): Cardinal;
  var
    idh: TImageDosHeader;
    inth: TImageNTHeaders;
    c: Cardinal;
  begin
    Result := 0;
     // Read DOS header of the module
    Toolhelp32ReadProcessMemory(cProcessID, pBAseAddr, idh, SizeOf(idh), c);
    if idh.e_magic=IMAGE_DOS_SIGNATURE then begin
       // Read NT header of the module
      Toolhelp32ReadProcessMemory(cProcessID, Pointer(Cardinal(pBaseAddr)+Cardinal(idh._lfanew)), inth, SizeOf(inth), c);
      if inth.Signature=IMAGE_NT_SIGNATURE then Result := inth.OptionalHeader.ImageBase;
    end;
  end;

  //====================================================================================================================
  // TToolHelp
  //====================================================================================================================

  constructor TToolHelper.Create(cFlags: Cardinal; cProcessID: Cardinal = 0);
  begin
    inherited Create;
    FHSnapshot := INVALID_HANDLE_VALUE;
    CreateSnapshot(cFlags, cProcessID);
  end;

  procedure TToolHelper.CreateSnapshot(cFlags, cProcessID: Cardinal);
  begin
    DestroySnapshot;
    if cFlags=0 then
      FHSnapshot := INVALID_HANDLE_VALUE
    else
      FHSnapshot := CreateToolhelp32Snapshot(cFlags, cProcessID);
  end;

  destructor TToolHelper.Destroy;
  begin
    DestroySnapshot;
    inherited Destroy;
  end;

  procedure TToolHelper.DestroySnapshot;
  begin
    if FHSnapshot<>INVALID_HANDLE_VALUE then CloseHandle(FHSnapshot);
  end;

{  function TToolHelp.ProcessFind(cProcessID: Cardinal; var pe: TProcessEntry32): Boolean;
  begin
    Result := False;

  end;
}
  function TToolHelper.ModuleFirst(var me: TModuleEntry32): Boolean;
  begin
    Result := Module32First(FHSnapshot, me);
  end;

  function TToolHelper.ModuleNext(var me: TModuleEntry32): Boolean;
  begin
    Result := Module32Next(FHSnapshot, me);
  end;

  function TToolHelper.ProcessFirst(var pe: TProcessEntry32): Boolean;
  begin
    Result := Process32First(FHSnapshot, pe);
     // Skip System Process (PID=0)
    if Result and (pe.th32ProcessID=0) then Result := ProcessNext(pe);
  end;

  function TToolHelper.ProcessNext(var pe: TProcessEntry32): Boolean;
  begin
    Result := Process32Next(FHSnapshot, pe);
     // Skip System Process (PID=0)
    if Result and (pe.th32ProcessID=0) then Result := ProcessNext(pe);
  end;

end.
