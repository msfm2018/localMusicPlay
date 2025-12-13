unit localSongs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,   ShellAPI,
  Vcl.StdCtrls, Unit1, core, Vcl.ExtCtrls, FileCtrl, types, ioutils, Vcl.Menus;

type
  Tfrm_local = class(TForm)
    songlst: TListBox;
    Timer1: TTimer;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure songlstDblClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
protected
  procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
  public
    { Public declarations }
  end;

var
  frm_local: Tfrm_local;

const
  AUDIO_EXTS: array[0..1] of string = ('*.mp3', '*.wav');

implementation

{$R *.dfm}

function PickFolders(var Dirs: TArray<string>): Boolean;
var
  Dialog: TFileOpenDialog;
begin
  Result := False;
  Dialog := TFileOpenDialog.Create(nil);
  try
    Dialog.Options := Dialog.Options + [fdoPickFolders, fdoAllowMultiSelect];
    Dialog.Title := '选择音乐文件夹（可多选）';

    if Dialog.Execute then
    begin
      Dirs := Dialog.Files.ToStringArray;
      Result := Length(Dirs) > 0;
    end;
  finally
    Dialog.Free;
  end;
end;

procedure AddSongSafe(const FullPath: string);
var
  Name: string;
  OriginalName: string; // 用于检查和生成唯一 Key
  Counter: Integer;
begin
  OriginalName := ChangeFileExt(ExtractFileName(FullPath), '');
  Name := OriginalName;
  Counter := 1;

  // 1. 检查 Value (路径) 是否重复。如果路径相同，则直接退出。
  if playDic.ContainsValue(FullPath) then
    Exit;

  // 2. 检查 Key (歌曲名) 是否重复。如果重复，生成一个新的唯一 Key。
  while playDic.ContainsKey(Name) do
  begin
    // 如果 Key 已经存在，则添加后缀 (e.g., "稻香 (2)", "稻香 (3)")
    Inc(Counter);
    Name := OriginalName + ' (' + IntToStr(Counter) + ')';

    // 理论上 Counter 不会超过某个限制，但为了安全，可以设置一个循环上限
    if Counter > 99 then
    begin
        // 如果尝试 100 次 Key 仍然重复，可能存在逻辑问题，暂时跳过
        Exit;
    end;
  end;

  // 3. 确定 Key 是唯一的后，进行添加
  playDic.Add(Name, FullPath); // Key 现在是唯一的

  // 4. 更新列表和 UI
  local_playlst.Add(Name + ',' + FullPath);
  frm_local.songlst.Items.Add(Name);
end;
    procedure AddSongsBatch(const Files: TArray<string>);
var
  FullPath, Name: string;
begin
  for FullPath in Files do
  begin
    if playDic.ContainsValue(FullPath) then
      Continue; // 去重（按完整路径）

    Name := ChangeFileExt(ExtractFileName(FullPath), '');

    playDic.Add(Name, FullPath);
    local_playlst.Add(Name + ',' + FullPath);
    frm_local.songlst.Items.Add(Name);
  end;
end;

procedure ScanFoldersAsync(const Dirs: TArray<string>);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Dir, Ext: string;
      Files: TStringDynArray;
    begin
      for Dir in Dirs do
        for Ext in AUDIO_EXTS do
        begin
          Files := TDirectory.GetFiles(
            Dir,
            Ext,
            TSearchOption.soAllDirectories
          );

          if Length(Files) = 0 then
            Continue;

          // 🔑 关键：一次性 Queue
          TThread.Queue(nil,
            procedure
            begin
              AddSongsBatch(Files);
            end);
        end;

      // 扫描完成后保存
      TThread.Queue(nil,
        procedure
        begin
          local_playlst.SaveToFile(g_lobal.appdir + './playlist');
        end);
    end
  ).Start;
end;


procedure Tfrm_local.FormCreate(Sender: TObject);
begin
DragAcceptFiles(Handle, True);
end;

procedure Tfrm_local.FormPaint(Sender: TObject);
var
  hr: Cardinal;
begin
  hr := createroundrectrgn(1, 1, Width - 2, Height - 2, 5, 5);
  setwindowrgn(Handle, hr, True);
end;

procedure aaa(dir: string; ext: string);
var
  files: TStringDynArray;
  str: string;
begin
  files := TDirectory.GetFiles(dir, ext, TSearchOption.soAllDirectories);

  for str in files do
  begin
    local_playlst.Add(Copy(ExtractFileName(str), 1, ExtractFileName(str).IndexOf('.')) + ',' + str);
  end;
end;

function PickFolder(var ADir: string): Boolean;
var
  Dialog: TFileOpenDialog;
begin
  Result := False;
  ADir := '';

  Dialog := TFileOpenDialog.Create(nil);
  try
    Dialog.Options := Dialog.Options + [fdoPickFolders];
    Dialog.Title := '选择音乐文件夹';

    if Dialog.Execute then
    begin
      ADir := Dialog.FileName;
      Result := True;
    end;
  finally
    Dialog.Free;
  end;
end;
procedure Tfrm_local.WMDropFiles(var Msg: TWMDropFiles);
var
  Count, I: Integer;
  // 推荐使用 PChar 或 PWideChar，或者指定 WideChar 数组
  // 在现代 Delphi 中 Char 就是 WideChar，但显式指定更安全
  Buffer: array[0..MAX_PATH - 1] of WideChar; // Windows路径是WideChar
  Dirs: TArray<string>;
  PathLen: Integer;
begin
  // 1. 获取文件数量
  Count := DragQueryFileW(Msg.Drop, $FFFFFFFF, nil, 0); // 明确调用W版本
  SetLength(Dirs, Count);

  for I := 0 to Count - 1 do
  begin
    // 2. 获取路径长度
    PathLen := DragQueryFileW(Msg.Drop, I, nil, 0);

    // 3. 再次调用获取路径内容
    // PathLen + 1 是所需的缓冲区大小（包括空终止符）
    PathLen := DragQueryFileW(Msg.Drop, I, Buffer, PathLen + 1);

    // 4. 将 WideChar 数组转换为 Delphi 的 Unicode String
    // 如果 PathLen > 0，则 Buffer 中包含了路径
    if PathLen > 0 then
      Dirs[I] := string(Buffer) // 隐式从 PWideChar 转换
    else
      Dirs[I] := '';
  end;

  DragFinish(Msg.Drop);
  ScanFoldersAsync(Dirs);
end;

procedure Tfrm_local.N1Click(Sender: TObject);
var
  sDir: string;
  arrs: TArray<string>;
  idx: Integer;
begin
  g_lobal.load_local_music;

  if PickFolder(sDir) then
    aaa(sDir, '*.mp3')
  else
    Exit;

  if local_playlst.Count <> 0 then
  begin
    local_playlst.SaveToFile(g_lobal.appdir + './playlist');
    songlst.Clear;
    playDic.Clear;

    for idx := 0 to local_playlst.Count - 1 do
    begin
      arrs := local_playlst.Strings[idx].Split([',']);
      if (Length(arrs) >= 2) and not playDic.ContainsKey(arrs[0]) then
      begin
        playDic.Add(arrs[0], arrs[1]);
        songlst.Items.Add(arrs[0]);
      end;
    end;
  end;
end;

procedure Tfrm_local.N2Click(Sender: TObject);
begin
  local_playlst.Delete(local_playlst.IndexOf(frm_local.songlst.Items[frm_local.songlst.ItemIndex] + ',' + playDic.Items[frm_local.songlst.Items[frm_local.songlst.ItemIndex]]));
  local_playlst.SaveToFile('./playlist');
  playDic.Remove(frm_local.songlst.Items[frm_local.songlst.ItemIndex]);
  frm_local.songlst.DeleteSelected;
end;

procedure Tfrm_local.N3Click(Sender: TObject);
begin
  frm_local.songlst.Clear;
  DeleteFile('playlist');
end;

procedure Tfrm_local.songlstDblClick(Sender: TObject);
begin
  if songlst.ItemIndex = -1 then
    Exit;
  g_init := False;
  g_lobal.HIDE_DESKTOP_BTN;
  Form1.img_default.BringToFront;

  urlPlayFlag := False;

  g_local_index := songlst.ItemIndex;

  if not g_lobal.LocalMusic(playDic.Items[songlst.Items[songlst.ItemIndex]]) then
    Form1.nextSong;

  g_lobal.load_local_music;
  g_lobal.load_pause_img;


  g_lobal.SHOW_DESKTOP_BTN;
  Close();
//
end;

procedure Tfrm_local.Timer1Timer(Sender: TObject);
begin
  if g_local_index = -1 then
    exit;

  songlst.Selected[g_local_index] := true;
end;

end.

