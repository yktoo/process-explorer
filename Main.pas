unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, ConsVarsTypes, 
  Dialogs, ExtCtrls, ComCtrls, TB2Item, ActnList, ImgList, TB2ExtItems,
  TB2Dock, TB2Toolbar, StdCtrls;

type
  TfMain = class(TForm)
    sMain: TSplitter;
    TheStatusBar: TStatusBar;
    dkTop: TTBDock;
    dkBottom: TTBDock;
    dkLeft: TTBDock;
    dkRight: TTBDock;
    tbMenu: TTBToolbar;
    tbMain: TTBToolbar;
    smFile: TTBSubmenuItem;
    smView: TTBSubmenuItem;
    smHelp: TTBSubmenuItem;
    iToggleToolbar: TTBVisibilityToggleItem;
    iToggleStatusBar: TTBVisibilityToggleItem;
    alMain: TActionList;
    ilMain: TTBImageList;
    aExit: TAction;
    aRefresh: TAction;
    aAbout: TAction;
    aAutoRefresh: TAction;
    iExit: TTBItem;
    bExit: TTBItem;
    TheTimer: TTimer;
    lvMaster: TListView;
    iViewSepRefresh: TTBSeparatorItem;
    iRefresh: TTBItem;
    iAbout: TTBItem;
    bAbout: TTBItem;
    bRefresh: TTBItem;
    tbSep2: TTBSeparatorItem;
    tbSep1: TTBSeparatorItem;
    pDetail: TPanel;
    lvDetail: TListView;
    lDetailInfo: TLabel;
    iAutoRefresh: TTBItem;
    bAutoRefresh: TTBItem;
    procedure aaExit(Sender: TObject);
    procedure aaRefresh(Sender: TObject);
    procedure aaAutoRefresh(Sender: TObject);
    procedure aaAbout(Sender: TObject);
    procedure TheTimerTick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvMasterChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure FormShow(Sender: TObject);
    procedure ListViewColumnClick(Sender: TObject; Column: TListColumn);
    procedure FormCreate(Sender: TObject);
    procedure lvMasterCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure lvDetailCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  private
     // Processes and modules sort specifiers
    FProcSort: TListViewSort;
    FModuleSort: TListViewSort;
     // Adjusts ListView's sort indicator
    procedure AdjustLVSortIndicator(LV: TListView);
     // Loads process list into a ListView
    procedure PopulateProcessList(LV: TListView);
     // Loads process list into a ListView
    procedure PopulateModuleList(LV: TListView; TH: TToolHelper);
     // Refreshes the screen
    procedure DoRefresh;
     // Displays info for the process
    procedure ShowProcessInfo(cProcessID: Cardinal);
     // Registry loading/storing
    procedure LoadSettings;
    procedure SaveSettings;
  end;

var
  fMain: TfMain;

implementation
{$R *.dfm}
uses
  TlHelp32,
  Registry
  {$IFDEF VER150}, XPMan{$ENDIF};

  procedure TfMain.aaAbout(Sender: TObject);
  begin
    Application.MessageBox(PChar(SMsg_AboutText), PChar(SMsg_AboutTitle), MB_OK or MB_ICONINFORMATION);
  end;

  procedure TfMain.aaAutoRefresh(Sender: TObject);
  begin
    TheTimer.Enabled := aAutoRefresh.Checked;
  end;

  procedure TfMain.aaExit(Sender: TObject);
  begin
    Close;
  end;

  procedure TfMain.aaRefresh(Sender: TObject);
  begin
    DoRefresh;
  end;

  procedure TfMain.AdjustLVSortIndicator(LV: TListView);
  var
    p: PListViewSort;
    i: Integer;
  begin
    p := PListViewSort(LV.Tag);
    for i := 0 to LV.Columns.Count-1 do LV.Columns[i].ImageIndex := aiiiSort[i=p^.iColIndex, p^.bSortDesc];
  end;

  procedure TfMain.DoRefresh;
  begin
    PopulateProcessList(lvMaster);
     // Restart the timer
    TheTimer.Enabled := False;
    if aAutoRefresh.Checked then TheTimer.Enabled := True;
  end;

  procedure TfMain.FormCreate(Sender: TObject);
  begin
    lvMaster.Tag := Integer(@FProcSort);
    AdjustLVSortIndicator(lvMaster);
    FModuleSort.iColIndex := 1; // Base address
    lvDetail.Tag := Integer(@FModuleSort);
    AdjustLVSortIndicator(lvDetail);
  end;

  procedure TfMain.FormDestroy(Sender: TObject);
  begin
    SaveSettings;
  end;

  procedure TfMain.FormShow(Sender: TObject);
  begin
    LoadSettings;
  end;

  procedure TfMain.ListViewColumnClick(Sender: TObject; Column: TListColumn);
  begin
    with PListViewSort(TListView(Sender).Tag)^ do begin
      if Column.Index=iColIndex then
        bSortDesc := not bSortDesc
      else begin
        bSortDesc := False;
        iColIndex := Column.Index;
      end;
      AdjustLVSortIndicator(TListView(Sender));
      TListView(Sender).AlphaSort;
    end;
  end;

  procedure TfMain.LoadSettings;
  var rif: TRegIniFile;
  begin
    rif := TRegIniFile.Create(SRegKey_Main);
    try
      with rif do begin
        SetBounds(
          ReadInteger(SRegSection_Preferences, 'Left',   Left),
          ReadInteger(SRegSection_Preferences, 'Top',    Top),
          ReadInteger(SRegSection_Preferences, 'Width',  Width),
          ReadInteger(SRegSection_Preferences, 'Height', Height));
        lvMaster.Width       := ReadInteger(SRegSection_Preferences, 'MasterWidth', 200);
        aAutoRefresh.Checked := ReadBool   (SRegSection_Preferences, 'AutoRefresh', False);
      end;
      TBRegLoadPositions(Self, HKEY_CURRENT_USER, SRegKey_Toolbars);
    finally
      rif.Free;
    end;
    DoRefresh;
  end;

  procedure TfMain.lvDetailCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  var
    iCol: Integer;
    s1, s2: String;
  begin
     // Obtain strings to compare
    iCol := FModuleSort.iColIndex;
    if iCol=0 then begin
      s1 := Item1.Caption;
      s2 := Item2.Caption;
    end else begin
      s1 := Item1.SubItems[iCol-1];
      s2 := Item2.SubItems[iCol-1];
    end;
     // Do compare
    case iCol of
      0, 3: Compare := StrToIntDef(s1, 0)-StrToIntDef(s2, 0);
      1, 2: Compare := StrToIntDef('$'+s1, 0)-StrToIntDef('$'+s2, 0);
      4:    Compare := AnsiCompareText(s1, s2);
    end;
    if FModuleSort.bSortDesc then Compare := -Compare;
  end;

  procedure TfMain.lvMasterChange(Sender: TObject; Item: TListItem; Change: TItemChange);
  begin
    Item := lvMaster.Selected;
    if Item<>nil then ShowProcessInfo(Cardinal(Item.Data));
  end;

  procedure TfMain.lvMasterCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  begin
    case FProcSort.iColIndex of
      0: Compare := Integer(Item1.Data)-Integer(Item2.Data);
      1: Compare := AnsiCompareText(Item1.SubItems[0], Item2.SubItems[0]);
    end;
    if FProcSort.bSortDesc then Compare := -Compare;
  end;

  procedure TfMain.PopulateModuleList(LV: TListView; TH: TToolHelper);
  var
    b: Boolean;
    me: TModuleEntry32;
    iSelIdx: Integer;
    cPreferredAddr: Cardinal;
  begin
     // Store selection
    iSelIdx := LV.ItemIndex;
     // Load modules
    LV.Items.BeginUpdate;
    try
      LV.Items.Clear;
       // Enumerate modules
      me.dwSize := SizeOf(me);
      b := TH.ModuleFirst(me);
      while b do begin
        cPreferredAddr := GetModulePreferredBaseAddr(me.th32ProcessID, me.modBaseAddr);
        with LV.Items.Add do begin
          ImageIndex := iiiLibrary;
           // Implicit load
          if me.ProccntUsage=65535 then
            Caption  := SModuleFixed
          else
            Caption  := IntToStr(me.ProccntUsage);
          SubItems.Add(Format('%.8x', [Cardinal(me.modBaseAddr)]));
           // If real base address differs from preferred one
          if Cardinal(me.modBaseAddr)=cPreferredAddr then
            SubItems.Add('')
          else
            SubItems.Add(Format('%.8x', [cPreferredAddr]));
          SubItems.Add(IntToStr(me.modBaseSize));
          SubItems.Add(me.szExePath);
        end;
        b := TH.ModuleNext(me);
      end;
       // Restore selection
      if iSelIdx<0 then iSelIdx := 0;
      if iSelIdx>=LV.Items.Count then iSelIdx := LV.Items.Count-1;
      if iSelIdx>=0 then LV.Items[iSelIdx].Selected := True;
    finally
      LV.Items.EndUpdate;
    end;
  end;

  procedure TfMain.PopulateProcessList(LV: TListView);
  var
    TH: TToolHelper;
    b: Boolean;
    pe: TProcessEntry32;
    cSelID: Cardinal;
    li, liSel: TListItem;
  begin
     // Store selection
    liSel := nil;
    if LV.Selected=nil then cSelID := 0 else cSelID := Cardinal(LV.Selected.Data);
     // Load processes
    TH := TToolHelper.Create(TH32CS_SNAPPROCESS);
    LV.Items.BeginUpdate;
    try
      LV.Items.Clear;
       // Enumerate processes
      pe.dwSize := SizeOf(pe);
      b := TH.ProcessFirst(pe);
      while b do begin
        li := LV.Items.Add;
        with li do begin
          Caption    := Format('%.8x', [pe.th32ProcessID]);
          ImageIndex := iiiProcess;
          Data       := Pointer(pe.th32ProcessID);
          SubItems.Add(ExtractFileName(pe.szExeFile));
        end;
        if pe.th32ProcessID=cSelID then liSel := li;
        b := TH.ProcessNext(pe);
      end;
       // Restore selection
      if liSel<>nil then liSel.Selected := True;
    finally
      LV.Items.EndUpdate;
      TH.Free;
    end;
  end;

  procedure TfMain.SaveSettings;
  var rif: TRegIniFile;
  begin
    rif := TRegIniFile.Create(SRegKey_Main);
    try
      with rif do begin
        WriteInteger(SRegSection_Preferences, 'Left',        Left);
        WriteInteger(SRegSection_Preferences, 'Top',         Top);
        WriteInteger(SRegSection_Preferences, 'Width',       Width);
        WriteInteger(SRegSection_Preferences, 'Height',      Height);
        WriteInteger(SRegSection_Preferences, 'MasterWidth', lvMaster.Width);
        WriteBool   (SRegSection_Preferences, 'AutoRefresh', aAutoRefresh.Checked);
      end;
      TBRegSavePositions(Self, HKEY_CURRENT_USER, SRegKey_Toolbars);
    finally
      rif.Free;
    end;
  end;

  procedure TfMain.ShowProcessInfo(cProcessID: Cardinal);
  var
    th: TToolHelper;
    pe: TProcessEntry32;
    b, bFound: Boolean;
  begin
    pe.dwSize := SizeOf(pe);
    th := TToolHelper.Create(TH32CS_SNAPALL, cProcessID);
    try
      bFound := False;
      b := th.ProcessFirst(pe);
      while b do begin
        if pe.th32ProcessID=cProcessID then begin
          lDetailInfo.Caption := Format(
            SProcessDetailFormat,
            [pe.szExeFile, pe.th32ProcessID, pe.th32ParentProcessID, pe.pcPriClassBase, pe.cntThreads]);
          bFound := True;
          Break;
        end;
        b := th.ProcessNext(pe);
      end;
       // Show module information
      if bFound then PopulateModuleList(lvDetail, th) else lvDetail.Clear;
      lDetailInfo.Visible := bFound;
    finally
      th.Free;
    end;
  end;

  procedure TfMain.TheTimerTick(Sender: TObject);
  begin
    DoRefresh;
  end;

end.
