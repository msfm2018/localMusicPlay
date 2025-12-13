unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Menus, FileCtrl, colorFrame, Vcl.StdCtrls,
  IOUtils, Types, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BASS, Vcl.ComCtrls,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.GDIPUTIL, Vcl.Buttons, Vcl.CheckLst,
  Vcl.ExtCtrls, Vcl.Grids, ImgPanel, Vcl.Imaging.pngimage, PluginCtrl,
  SuperObject, System.Generics.Collections, System.StrUtils,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  math,  Vcl.Imaging.jpeg, IdBaseComponent, IdComponent, IdTCPConnection,
  ULrcShow, IdTCPClient, IdHTTP, Animation, UrlSongs, System.Win.Registry,
  UrlMon, System.ImageList, Vcl.ImgList, Vcl.WinXCtrls, core, GDILyrics;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    TrayIcon1: TTrayIcon;
    PopupMenu2: TPopupMenu;
    N6: TMenuItem;
    img_default: TImage;
    N7: TMenuItem;
    IMG_START: TImage;
    IMG_next: TImage;
    img_list: TImage;
    N9: TMenuItem;
    N1: TMenuItem;
    Timer2: TTimer;
    pbVisual: TPaintBox;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure IMG_STARTClick(Sender: TObject);
    procedure IMG_nextClick(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N6Click(Sender: TObject);

    procedure img_defaultMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure N7Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure IMG_STARTMouseEnter(Sender: TObject);
    procedure IMG_STARTMouseLeave(Sender: TObject);
    procedure IMG_nextMouseEnter(Sender: TObject);
    procedure IMG_nextMouseLeave(Sender: TObject);
    procedure img_listMouseEnter(Sender: TObject);
    procedure img_listMouseLeave(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure img_listClick(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure pbVisualPaint(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);

  private

  public
    procedure nextSong();
  end;

  tplaySong = class(TThread)
  private
    lrclst: TStringList;
  public
    constructor create(songlst: TStringList);
    procedure execute; override;
  end;

var
  Form1: TForm1;
  item, jo: ISuperObject;
  var
  BarValue: array[0..47] of Single;
var
  FFT: array[0..1023] of Single;
  FFTSmooth: array[0..1023] of Single;
  LyricProgress: Double = 0.0;

var
  MusicEnergy: Single = 0.0;

implementation

{$R *.dfm}

uses
  ActiveX, ComObj, ShlObj, localSongs;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  playDic.Free;
  g_song_Info_list.Free;
  BASS_Free;
  TrayIcon1.Visible := False;
  urlplaylist.Free;
  chane_list.Free;
  jpgpic.Free;
  mspic.Free;
  lrclst.Free;
  local_playlst.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  hr: THandle;
begin

  g_lobal.appdir := ExtractFilePath(ParamStr(0));
  DoubleBuffered := true;
  urlplaylist := tstringlist.create;
  chane_list := TList<tchannel_list>.create;
  mspic := TMemoryStream.create;
  jpgpic := TJPEGImage.create;
  lrclst := TStringList.Create; // TList<string>.create();
  playDic := TDictionary<string, string>.create();
  g_song_Info_list := TList<tplay_list>.create();

  BorderStyle := bsNone;

  if HiWord(BASS_GetVersion) <> BASSVERSION then
    MessageBox(0, '"Bass.dll" 文件版本不合适! ', nil, MB_ICONERROR);

  if not BASS_Init(-1, 44100, 0, 0, nil) then
  begin
    ShowMessage('没有声卡');
    Application.Terminate;
  end;
  BASS_SetConfig(BASS_CONFIG_NET_PLAYLIST, 1);
  hr := createroundrectrgn(1, 1, Width - 2, Height - 2, 5, 5);
  setwindowrgn(Handle, hr, True);

  BringWindowToTop(Handle);



  local_playlst := tstringlist.create;

//  img_default.Picture.LoadFromFile('img/background.bmp');

  g_lobal.textout('山间音乐', img_default.Canvas, 10, 10, 100, 10, 10);

  with pbVisual do
  begin
    Align := alBottom;
    Height := 140;
    Color := clBlack;
  end;




end;

procedure TForm1.FormShow(Sender: TObject);
begin
  form1.Left := (screen.WorkAreaWidth - form1.Width div 2) div 2;
  frmLrcShow.Width := form1.Width;
  frmLrcShow.Top := Screen.WorkAreaHeight - frmLrcShow.height;
  frmLrcShow.Left := form1.Left - frmLrcShow.Width div 4;

  frmLrcShow.show;

end;

procedure TForm1.Image1Click(Sender: TObject);
begin

  g_lobal.SHOW_DESKTOP_BTN;
end;

procedure TForm1.IMG_STARTMouseEnter(Sender: TObject);
begin
  if g_init then
  begin
    if IMG_START.Tag = 2 then
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\a2.png')
    else
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\p2.png');
  end
  else
  begin
    if IMG_START.Tag = 2 then
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\p2.png')
    else
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\a2.png');

  end;
end;

procedure TForm1.IMG_STARTMouseLeave(Sender: TObject);
begin
  if g_init then
  begin
    if IMG_START.Tag = 2 then
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\a1.png')
    else
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\p1.png');

  end
  else
  begin
    if IMG_START.Tag = 2 then
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\p1.png')
    else
      Form1.IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img\a1.png');

  end;
end;

var
  img_index: Integer;

var
  gsname: string;

var
  lrcShowB: Boolean = false;
  fend: Boolean = false;
  playSong: tplaySong;

procedure AddRoundRect(Path: TGPGraphicsPath; const R: TGPRectF; Radius: Single);
var
  D: Single;
begin
  D := Radius * 2;

  Path.AddArc(R.X, R.Y, D, D, 180, 90);
  Path.AddArc(R.X + R.Width - D, R.Y, D, D, 270, 90);
  Path.AddArc(R.X + R.Width - D, R.Y + R.Height - D, D, D, 0, 90);
  Path.AddArc(R.X, R.Y + R.Height - D, D, D, 90, 90);
  Path.CloseFigure;
end;


procedure TForm1.Timer2Timer(Sender: TObject);
var
  I: Integer;
  Energy: Single;
begin
  if Stream = 0 then Exit;

  BASS_ChannelGetData(Stream, @FFT, BASS_DATA_FFT2048);

  Energy := 0;
  for I := 0 to 200 do
  begin
    FFTSmooth[I] := FFTSmooth[I] * 0.75 + FFT[I] * 0.25;
    Energy := Energy + FFTSmooth[I];
  end;

  MusicEnergy := MusicEnergy * 0.85 + Energy * 0.15;

  pbVisual.Invalidate;
end;


procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  Self.Visible := true;
  if frm_url.songlst.Count > 0 then
    frm_url.Visible := true;
  SetWindowPos(Form1.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  SetWindowPos(Form1.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.IMG_STARTClick(Sender: TObject);
begin
  if not urlPlayFlag then
  begin
    if frm_local.songlst.ItemIndex = -1 then
      Exit;

    case IMG_START.Tag of
      1:
        begin
          if time <> 0 then
          begin
            IMG_START.Tag := 2;
            BASS_ChannelPlay(Stream, False);
          end;

        end;
      2:
        begin
          IMG_START.Tag := 1;

          BASS_ChannelPause(Stream);

          g_lobal.SHOW_DESKTOP_BTN;

        end;

    end;
  end
  else
  begin

    case IMG_START.Tag of
      1:
        begin
          if time <> 0 then
          begin
            g_lobal.SHOW_DESKTOP_BTN;
            IMG_START.Tag := 2;
            BASS_ChannelPlay(Stream, False);
          end;
        end;
      2:
        begin
          IMG_START.Tag := 1;

          BASS_ChannelPause(Stream);
          IMG_START.Picture.LoadFromFile(g_lobal.appdir + 'img/a1.png');
        end;

    end;
  end;

end;

procedure TForm1.img_listClick(Sender: TObject);
begin
  N7Click(Self);
end;

procedure TForm1.img_listMouseEnter(Sender: TObject);
begin

  Form1.img_list.Picture.LoadFromFile(g_lobal.appdir + 'img\l2.png');
end;

procedure TForm1.img_listMouseLeave(Sender: TObject);
begin
  Form1.img_list.Picture.LoadFromFile(g_lobal.appdir + 'img\l1.png');
end;

procedure TForm1.img_defaultMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture; // 释放鼠标控制区域
  SendMessage(Handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

var
  icount: integer = 0;

procedure TForm1.IMG_nextClick(Sender: TObject);
begin

  nextSong;
end;

procedure TForm1.IMG_nextMouseEnter(Sender: TObject);
begin
  IMG_next.Picture.LoadFromFile(g_lobal.appdir + 'img\n2.png');

end;

procedure TForm1.IMG_nextMouseLeave(Sender: TObject);
begin
  IMG_next.Picture.LoadFromFile(g_lobal.appdir + 'img\n1.png');
end;

procedure TForm1.N1Click(Sender: TObject);
begin
  Self.Visible := False;
  if frm_url <> nil then
  begin
    frm_url.Visible := false;
  end;

  if frm_local <> nil then
  begin
    frm_local.Visible := false;
  end;

  if not urlPlayFlag then
  begin
    if frmLrcShow <> nil then
      frmLrcShow.Visible := false;

  end;
end;

procedure TForm1.N2Click(Sender: TObject);
begin
N1Click(Self);
end;

procedure TForm1.N3Click(Sender: TObject);
begin
    TrayIcon1.Free;
  Application.Terminate;
end;

procedure TForm1.N6Click(Sender: TObject);
begin
  TrayIcon1.Free;
  Application.Terminate;
end;

procedure TForm1.N7Click(Sender: TObject);
begin

  frm_url.Visible := False;

  if not Assigned(frm_local) then
    Exit;

  if frm_local.Visible then
  begin
    frm_local.Hide;
    Exit;
  end;

  g_lobal.load_local_music;
  frm_local.Left := Left + Width + 5;
  frm_local.Top := Top + (Height - frm_local.Height) div 2;
  frm_local.Show;

end;

procedure TForm1.nextSong;
begin
  sum_time := 0;

  if frm_local.songlst.ItemIndex = -1 then
    Exit;
  g_local_index := g_local_index + 1;

  if g_local_index >= frm_local.songlst.Count then
    Exit;

  g_lobal.load_pause_img;

  if not g_lobal.LocalMusic(playDic.Items[frm_local.songlst.Items[g_local_index]]) then
    nextSong
end;

procedure TForm1.pbVisualPaint(Sender: TObject);
var
  C: TCanvas;
  I, Bars, BarW, H, BaseY, Center: Integer;
  V: Single;
  Bright: Integer;
  X1, X2: Integer;
begin
  C := pbVisual.Canvas;

  C.Brush.Color := clBlack;
  C.FillRect(pbVisual.ClientRect);

  Bars   := 48;
  BarW   := pbVisual.Width div Bars;
  BaseY  := pbVisual.Height div 2;
  Center := Bars div 2;

  Bright := 120 + Round(MusicEnergy * 20);
  if Bright > 255 then Bright := 255;

  C.Pen.Style := psClear;
  C.Brush.Color := RGB(80, Bright, 240);

  for I := 0 to Bars - 1 do
  begin
    V := FFTSmooth[Abs(I - Center) * 4];

    // 柱子上升/下落（稳定）
    if V > BarValue[I] then
      BarValue[I] := V
    else
      BarValue[I] := BarValue[I] * 0.92;

    H := Round(BarValue[I] * (BaseY - 8));
    if H < 2 then Continue;

    X1 := I * BarW + 2;
    X2 := X1 + BarW - 4;

    C.RoundRect(X1, BaseY - H, X2, BaseY, 6, 6);
    C.RoundRect(X1, BaseY + 2, X2, BaseY + 2 + H div 2, 6, 6);
  end;
end;



{ tplaySong }
function GetWordByTime(AList: TStringList; AStartTime: Int64; var AProgress: Double): string;
var
  I: Integer;
  str: string;
  minute, second, msecond, pos: Integer;
  between, ms, totalMs, totalMs2: Int64;
begin
  totalMs := 0;
  for I := 0 to AList.Count - 1 do
  begin
    str := AList[I];
    minute := StrToInt(str.Substring(1, 2));
    second := StrToInt(str.Substring(4, 2));
    pos := str.IndexOf(']');
    msecond := StrToInt(str.Substring(7, pos - 7));
    ms := minute * 60 * 1000 + second * 1000 + msecond;
    totalMs2 := totalMs + ms;
    str := str.Substring(pos + 1);
    between := GetTickCount - AStartTime;
    if (between >= totalMs) and (between < totalMs2) then
    begin
      Result := str;
      AProgress := (between - totalMs) * 1.0 / ms;
      break;
    end;
    totalMs := totalMs2;
  end;
end;

constructor tplaySong.create(songlst: TStringList);
begin
  inherited create(True);
  FreeOnTerminate := true;
  lrclst := songlst;
end;

procedure tplaySong.execute;
var
  i: Integer;
  stime, l1, l2: string;
  curTime: Double;
  r1, progress: double;
  rr: Integer;
  xx, tmp, tmp2: TArray<string>;
begin
  for i := 0 to lrclst.Count - 1 do
  begin
    l1 := lrclst[i];
    if (i + 1) < lrclst.Count then
      l2 := lrclst[i + 1]
    else
      l2 := l1;
    curTime := Bass_ChannelBytes2Seconds(Stream, Bass_ChannelGetPosition(Stream, BASS_POS_BYTE));

    xx := l1.Split([']']);
    stime := xx[0].Substring(1);
    tmp := stime.Split([':']);
    tmp2 := tmp[1].Split(['.']);

           //  if tmp2[0][1]='0' then
    r1 := StrToInt(tmp[0]) * 60 * 1000 + StrToInt(tmp2[0]) * 1000 + StrToInt(tmp2[1]);


    rr := g_lobal.getXSecond(l1, l2);
    gGDILyric.FirstString := l1;
    gGDILyric.FirstStrWidth := LyricTextW(l1);
    gGDILyric.SetProgress(progress);
    LyricProgress := progress;

      //gGDILyric.SetPositionAndFlags(gGDILyric.FirstStrWidth * progress);
    gGDILyric.Invalidate;
//      Debug.Show(IntToStr(rr) + '  ' + l1);
    Sleep(rr);
  end;

end;

end.

