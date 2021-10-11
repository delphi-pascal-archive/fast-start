{
   Автор: RusMaXXX - Кутушев Руслан
   e-mail: soft205@mail.ru
   Дата создания: 26.04.2009
}

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ShellApi, IdBaseComponent, IdAntiFreezeBase, IdAntiFreeze,
  XPMan, ImgList, ExtCtrls, StdCtrls, ComCtrls, Registry, IniFiles;

const
  WM_MYICONNOTIFY = WM_USER + 123;
  AppName = 'Fast start of the programs';
  ConfigFile = 'DataProFile.krs';
  IniTemp = 'ON/OFF autorun program';

type
  TMainForm = class(TForm)
    MainPopupMenu: TPopupMenu;
    bt_about: TMenuItem;
    bt_line_2: TMenuItem;
    bt_config: TMenuItem;
    bt_line_3: TMenuItem;
    bt_exit: TMenuItem;
    ida: TIdAntiFreeze;
    XPManifest: TXPManifest;
    sImage: TImageList;
    line: TSplitter;
    bt_OK: TButton;
    bt_cancel: TButton;
    box_shortcut: TGroupBox;
    del_shortcut: TButton;
    add_shortcut: TButton;
    box_autorun: TCheckBox;
    OpenDialog: TOpenDialog;
    list_shortcut: TListBox;
    Icon_Small: TImageList;
    ListPopupMenu: TPopupMenu;
    clear_shortcut: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure bt_exitClick(Sender: TObject);
    procedure bt_configClick(Sender: TObject);
    procedure bt_cancelClick(Sender: TObject);
    procedure del_shortcutClick(Sender: TObject);
    procedure add_shortcutClick(Sender: TObject);
    procedure bt_OKClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure list_shortcutDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure list_shortcutMeasureItem(Control: TWinControl;
      Index: Integer; var Height: Integer);
    procedure box_autorunClick(Sender: TObject);
    procedure bt_aboutClick(Sender: TObject);
    procedure list_shortcutKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure clear_shortcutClick(Sender: TObject);
  private
    { Private declarations }
    ShownOnce: Boolean;
    procedure HideItemClick(Sender: TObject);
  public
    { Public declarations }
    procedure WMICON(var msg: TMessage); message WM_MYICONNOTIFY;
    procedure WMSYSCOMMAND(var msg: TMessage); message WM_SYSCOMMAND;
    procedure WMDropFiles(var M: TMessage); message WM_DROPFILES;
    procedure sViewMainForm;
    procedure ViewMain(Sender: TObject);
    procedure HideMainForm;
    procedure CreateTrayIcon;
    procedure DeleteTrayIcon;
    procedure LoadData(Data: TListBox);
    procedure SaveData(Data: TListBox);
    procedure CreateMenu(Data: TListBox);
    procedure ActionMenu(Sender: TObject);
    procedure AutoRun(sBool: Boolean);
  end;

var
  MainForm: TMainForm;
  sIniFile: TIniFile;

implementation

{$R *.dfm}

procedure TMainForm.WMDropFiles(var M: TMessage);
var
  i, CountFiles, SizeName, cch, hDrop: integer;
  lpszFile: PChar;
  Point: TPoint;
begin
  hDrop := M.WParam;
  DragQueryPoint(hDrop, Point);
  CountFiles := DragQueryFile(hDrop, $FFFFFFFF, nil, cch);
  for i := 0 to CountFiles - 1 do
  begin
    SizeName := DragQueryFile(hDrop, i, nil, cch);
    GetMem(lpszFile, SizeName + 1);
    DragQueryFile(hDrop, i, lpszFile, SizeName + 1);
    list_shortcut.Items.Add(lpszFile);
    FreeMem(lpszFile, SizeName + 1);
  end;
  DragFinish(hDrop);
end;

function GetWinDir : string;
var
  pWindowsDir : array [0..MAX_PATH] of Char;
  sWindowsDir : string;
begin
  GetWindowsDirectory (@pWindowsDir, MAX_PATH);
  sWindowsDir := StrPas (pWindowsDir);
  Result := sWindowsDir;
end;

function CopyDir(const fromDir, toDir: string): Boolean;
var
  fos: TSHFileOpStruct;
begin
  ZeroMemory(@fos, SizeOf(fos));
  with fos do
  begin
    wFunc  := FO_COPY;
    fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
    pFrom  := PChar(fromDir + #0);
    pTo    := PChar(toDir)
  end;
  Result := (0 = ShFileOperation(fos));
end;

procedure TMainForm.WMICON(var msg: TMessage);
var
  P: TPoint;
begin
  case msg.LParam of
    WM_RBUTTONDOWN:
      begin
        GetCursorPos(p);
        SetForegroundWindow(Application.MainForm.Handle);
        MainPopupMenu.Popup(P.X - 5, P.Y - 5);
      end;
     WM_LBUTTONDOWN:
      begin
        CreateMenu(list_shortcut);
        GetCursorPos(p);
        SetForegroundWindow(Application.MainForm.Handle);
        ListPopupMenu.Popup(P.X - 5, P.Y - 30);
      end;
  end;
end;

procedure TMainForm.WMSYSCOMMAND(var msg: TMessage);
begin
  inherited;
  if (Msg.wParam = SC_MINIMIZE) then HideItemClick(Self);
end;

procedure TMainForm.HideMainForm;
begin
  Application.ShowMainForm := False;
  ShowWindow(Application.Handle, SW_HIDE);
  ShowWindow(Application.MainForm.Handle, SW_HIDE);
end;

procedure TMainForm.sViewMainForm;
var
  i, j: Integer;
begin
  Application.ShowMainForm := True;
  ShowWindow(Application.Handle, SW_RESTORE);
  ShowWindow(Application.MainForm.Handle, SW_RESTORE);
  if not ShownOnce then
  begin
    for I := 0 to Application.MainForm.ComponentCount - 1 do
      if Application.MainForm.Components[I] is TWinControl then
        with Application.MainForm.Components[I] as TWinControl do
          if Visible then
          begin
            ShowWindow(Handle, SW_SHOWDEFAULT);
            for J := 0 to ComponentCount - 1 do
              if Components[J] is TWinControl then
                ShowWindow((Components[J] as TWinControl).Handle, SW_SHOWDEFAULT);
          end;
    ShownOnce := True;
  end;    
end;

procedure TMainForm.CreateTrayIcon;
var
  nidata: TNotifyIconData;
begin
  with nidata do
  begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := Self.Handle;
    uID := 1;
    uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallBackMessage := WM_MYICONNOTIFY;
    hIcon := Application.Icon.Handle;
    StrPCopy(szTip, AppName);
  end;
  Shell_NotifyIcon(NIM_ADD, @nidata);
end;

procedure TMainForm.DeleteTrayIcon;
var
  nidata: TNotifyIconData;
begin
  with nidata do
  begin
    cbSize := SizeOf(TNotifyIconData);
    Wnd := Self.Handle;
    uID := 1;
  end;
  Shell_NotifyIcon(NIM_DELETE, @nidata);
end;

procedure TMainForm.ViewMain(Sender: TObject);
begin
  sViewMainForm;
end;

procedure TMainForm.HideItemClick(Sender: TObject);
begin
  HideMainForm;
  CreateTrayIcon;
end;

procedure TMainForm.LoadData(Data: TListBox);
begin
  if FileExists(GetWinDir +'\'+ ConfigFile) then
     Data.Items.LoadFromFile(GetWinDir +'\'+ ConfigFile);
  box_autorun.Checked := sIniFile.ReadBool('config', IniTemp, False);
end;

procedure TMainForm.SaveData(Data: TListBox);
begin
  Data.Items.SaveToFile(GetWinDir +'\'+ ConfigFile);
  sIniFile.WriteBool('config', IniTemp, box_autorun.Checked);
end;

procedure TMainForm.ActionMenu(Sender: TObject);
  function RunAction(WND: HWND; const FileName, Params,
           DefaultDir: string; ShowCmd: Integer): THandle;
  var
    zFileName, zParams, zDir: array[0..79] of Char;
  begin
    Result := ShellExecute(WND,nil,
    StrPCopy(zFileName, FileName),StrPCopy(zParams, Params),
    StrPCopy(zDir, DefaultDir), ShowCmd);
  end;
var
  ID_Tag: integer;
begin
  ID_Tag := (Sender as TMenuItem).Tag ;
  RunAction(0, list_shortcut.Items.Strings [ID_Tag], '', '', SW_SHOW); 
end;

procedure TMainForm.AutoRun(sBool: boolean);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create ;
  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', true) then
    begin
      if sBool then
      begin
        if not FileExists(GetWinDir + '\' + AppName + '.exe') then
           CopyDir (Application.ExeName, GetWinDir + '\' + AppName + '.exe');
        Reg.WriteString(AppName, GetWinDir + '\' + AppName + '.exe');
      end
      else
      begin
        if Reg.ValueExists(AppName) then
           Reg.DeleteValue (AppName);
      end;
    end;
  finally
    Reg.Free;
    inherited;
  end;
end; 
 
procedure TMainForm.CreateMenu(Data: TListBox);
  procedure AddIcon(Data: TListBox);
  var
    ID_Icon: TIcon;
    i, Index: word;
  begin
    Icon_Small.Clear;
    ID_Icon := TIcon.Create;
    if Data.Items.Count > 0 then
    begin
      for i := 0 to Data.Count - 1 do
      begin
        ID_Icon.Handle := ExtractAssociatedIcon(Hinstance, PChar(Data.Items.Strings[i]), Index);
        Icon_Small.AddIcon(ID_Icon);
      end;
    end;
  end;
var
  i, Index: Word;
  Item: TMenuItem;
  ID_Icon: TIcon;
begin
  if FileExists(GetWinDir +'\'+ ConfigFile) and (Data.Items.Count > 0) then
  begin
    AddIcon(Data);
    with ListPopupMenu.Items do
    begin
      AddIcon(Data);
      while Count > 0 do Items[0].Free;
      if Data.Count > 0 then
      begin
        for i := 0 to Data.Count - 1 do
        begin
          ID_Icon := TIcon.Create;
          ID_Icon.Handle := ExtractAssociatedIcon(Hinstance, PChar(Data.Items.Strings[i]), Index);
          Item := TMenuItem.Create(ListPopupMenu);
          Item.Caption := ExtractFileName(Data.Items.Strings [i]);
          Item.Tag := i;
          Item.ImageIndex := i;
          Item.OnClick := ActionMenu;
          Add(Item);
        end;
      end;
    end;
  end else
  begin
    with ListPopupMenu.Items do
    begin
      while Count > 0 do Items[0].Free;
      Add(NewItem('Нет программ', 0, False, False, nil, 0, 'MenuItem'))
    end;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
  MainForm.Left := (Screen.Width div 2) - (MainForm.Width div 2);
  MainForm.Top := (Screen.Height div 2) - (MainForm.Height div 2);
  ShownOnce := False;
  CreateTrayIcon;
  ShowWindow(Application.Handle, SW_HIDE);
  Application.ShowMainForm := FALSE;
  sIniFile := TIniFile.Create (AppName + '.ini');
  LoadData(list_shortcut);
  MainForm.Caption := 'Настройки - ' + AppName; 
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  DeleteTrayIcon;
end;

procedure TMainForm.FormHide(Sender: TObject);
begin
  Application.Minimize ;
end;

procedure TMainForm.bt_exitClick(Sender: TObject);
begin
  SaveData(list_shortcut);
  Application.Terminate ;
end;

procedure TMainForm.bt_configClick(Sender: TObject);
begin
  ViewMain(Sender);
end;

procedure TMainForm.bt_cancelClick(Sender: TObject);
begin
  HideMainForm;
end;

procedure TMainForm.del_shortcutClick(Sender: TObject);
begin
  list_shortcut.DeleteSelected;
end;

procedure TMainForm.add_shortcutClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    list_shortcut.Items.Add (OpenDialog.FileName);
  end;
end;

procedure TMainForm.bt_OKClick(Sender: TObject);
begin
  SaveData(list_shortcut);
  HideMainForm;
end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  CreateMenu(list_shortcut);
end;

procedure TMainForm.list_shortcutDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  ID: Word;
  Icon: TIcon;
begin
  with (Control as TListBox).Canvas do
  begin
    FillRect(Rect);
    Icon := TIcon((Control as TListBox).Items.Objects[Index]);
    DrawIconEx(Handle, Rect.Left + 5, Rect.Top,
               ExtractAssociatedIcon(Hinstance, PChar((Control as TListBox).Items.Strings [index]), ID),
               16, 16, 0, 0, DI_NORMAL);
    TextOut(Rect.Left + 28, Rect.Top + 1, (Control as TListBox).Items[Index])
  end;
end;

procedure TMainForm.list_shortcutMeasureItem(Control: TWinControl;
  Index: Integer; var Height: Integer);
begin
  Height := 16;
end;

procedure TMainForm.box_autorunClick(Sender: TObject);
begin
  if box_autorun.Checked then
    AutoRun(True)
  else
    AutoRun (False);
end;

procedure TMainForm.bt_aboutClick(Sender: TObject);
var
  AMsgDialog: TForm;
  HM: THandle;
const
  Msg_Caption = 'О программе ...';
  Msg_TXT = 'Программа ' + AppName + ' версия 1.0' + #13#10 +
            'Предназначенна для ускорения запуска программ,' + #13#10 +
            'так же способствует не загрязнению рабочего стола.. ;-)' + #13#13#10 +
            'Почта для пожеланий и предложений: soft205@mail.ru';
begin
  beep;
  AMsgDialog := CreateMessageDialog(Msg_TXT, mtInformation, [mbOK]);
  with AMsgDialog do
    try
      Caption := Msg_Caption ;;
      case ShowModal of
        ID_OK: Exit;
      end;
    finally
      Free;
    end;
end;

procedure TMainForm.list_shortcutKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_DELETE then list_shortcut.DeleteSelected; 
end;

procedure TMainForm.clear_shortcutClick(Sender: TObject);
var
  AMsgDialog: TForm;
  HM: THandle;
const
  Msg_Caption = 'Подтверждение ...';
  Msg_TXT = 'Вы действительно хотите очистить список?';
begin
  beep;
  AMsgDialog := CreateMessageDialog(Msg_TXT, mtInformation, [mbNo, mbOK]);
  with AMsgDialog do
    try
      Caption := Msg_Caption ;;
      case ShowModal of
        ID_OK: list_shortcut.Clear;
        ID_NO: Exit;
      end;
    finally
      Free;
    end;
end;

end.
