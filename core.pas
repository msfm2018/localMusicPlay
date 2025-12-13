unit core;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Menus, FileCtrl, colorFrame, Vcl.StdCtrls, IOUtils, Types,
  Winapi.ShlObj, ComObj, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, BASS, Vcl.ComCtrls,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, Winapi.GDIPUTIL, Vcl.Buttons, Vcl.CheckLst,
  Vcl.ExtCtrls, Vcl.Grids, ImgPanel, Vcl.Imaging.pngimage, PluginCtrl,
  SuperObject, System.Generics.Collections, System.StrUtils, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent,  Vcl.Imaging.jpeg,
  IdBaseComponent, IdComponent, IdTCPConnection, Winapi.ActiveX, IdTCPClient,
  IdHTTP, Animation, UrlSongs, System.Win.Registry, UrlMon, System.ImageList,
  Vcl.ImgList, Vcl.WinXCtrls;

type
  tchannel_list = record
    channel_id, channel_name, channel_order, cate_id, cate, cate_order, source_type, source_id, pv_order: string;
  end;

  tplay_list = record
    songName, artistName, albumName, songPicSmall, lrcLink, songPicBig, songPicRadio: string;
    songLink: AnsiString;
  end;

  tglobal = record
    procedure load_local_music;
    function DownloadMp3(Source, Dest, realname: string): Boolean;
    procedure load_play_img;
    procedure load_pause_img;
    procedure HIDE_DESKTOP_BTN;
    procedure SHOW_DESKTOP_BTN;

    function LocalMusic(song_file: AnsiString): Boolean;
  public
    appdir: string;
    g_songName, g_artistName: string;
    g_song_index: integer;
    one: Integer;
    playflag: Boolean;
  public
    procedure load_play_img_pause;
    procedure textout(txt: string; canvas: tcanvas; x, y: integer; r, g, b: byte);
    procedure textoutA(txt: string; canvas: tcanvas; x, y, fontsize: integer; r, g, b: byte);
    procedure freeStream(Stream: HSTREAM);


    function GetWordByTime(AList: TStringList; AStartTime: Int64; var AProgress: Double): string;
    function getXSecond(v1, v2: string): integer;
  end;

var
  g_init: Boolean = true;
  js: ISuperObject;

var
  playDic: TDictionary<string, string>;
  bpause: Boolean = False;
  sum_time: Double; { 乐曲总时间 }

  local_playlst: tstringlist;
  Stream: HSTREAM;

var
  chane_list: TList<tchannel_list>;
  urlplaylist: tstringlist;
  urlPlayFlag: Boolean;
  songinfo: tplay_list;

var
  mspic: TMemoryStream;
  jpgpic: TJPEGImage;
  jpgtag: Integer = 0;

var
  lrclst: TStringList; // TList<string>;



var
  g_song_Info_list: TList<tplay_list>;
  g_local_index: integer = -1;
  g_play_list: tplay_list;

var
  ja: TSuperArray;
  jss: ISuperObject;
  g_lobal: tglobal;

const
  WM_ME = WM_USER + 1000; //自定义消息；
  WM_MYPAINT = WM_USER + 1001; //自定义消息；

procedure GetLyric2(FileName: string); // 获取歌词部分的时候把没有歌词部分的时间轴去掉

implementation

uses
  Unit1, localSongs;
{ tglobal }

procedure tglobal.freeStream(Stream: HSTREAM);
begin
  BASS_ChannelStop(Stream);
  BASS_StreamFree(Stream);
  Stream := 0;
end;

procedure PlayFinishCallBack(Handle: HSYNC; channel, Data, user: DWORD); stdcall;
begin
  sum_time := 0;

  g_lobal.freeStream(Stream);

  if not urlPlayFlag then
  begin
    if frm_local.songlst.ItemIndex = -1 then
      Exit;
    Form1.nextSong;
  end
  else
  begin
    try
      Form1.nextSong;
    except
      urlPlayFlag := False;
      Inc(g_lobal.g_song_index);
      Form1.nextSong;
    end;
  end;
  g_lobal.one := 0;
end;

function tglobal.getXSecond(v1, v2: string): integer;
var
  xx, tmp, tmp2: TArray<string>;
  stime: string;
  r1: integer;
begin
  xx := v1.Split([']']);
  stime := xx[0].Substring(1);
  tmp := stime.Split([':']);
  tmp2 := tmp[1].Split(['.']);

     //  if tmp2[0][1]='0' then
        r1 := StrToInt(tmp[0]) * 60  * 1000     + StrToInt(tmp2[0]) * 1000 + StrToInt(tmp2[1]) ;//else
      //   r1 := StrToInt(tmp[0]) * 60  * 1000     + StrToInt(tmp2[0]) * 100 + StrToInt(tmp2[1]) ;




  xx := v2.Split([']']);
  stime := xx[0].Substring(1);
  tmp := stime.Split([':']);
  tmp2 := tmp[1].Split(['.']);

 // if tmp2[0][1]='0' then
  result := StrToInt(tmp[0]) * 60  * 1000     + StrToInt(tmp2[0]) * 1000 + StrToInt(tmp2[1]);// else
  // result := StrToInt(tmp[0]) * 60  * 1000     + StrToInt(tmp2[0]) * 100 + StrToInt(tmp2[1])  ;

 // result := StrToInt(tmp[0]) * 60  * 1000 + StrToInt(tmp2[0]) * 1000 + StrToInt(tmp2[1]);
  result := (result - r1); // / 1000;  //

//  result := result /Length(v1)  ;//101

  //  v1 := getSecond(s);
  //  v2 := getSecond(s1);
  //  value := (v2 - v1) / 1000;
  //  ff :=value/ Length(s)  ;
end;

function tglobal.GetWordByTime(AList: TStringList; AStartTime: Int64; var AProgress: Double): string;
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
    //OutputDebugString(PChar('>>> between = ' + IntToStr(between) + '  totalMs=' + IntToStr(totalMs) + '  totalMs2=' + IntToStr(totalMs2)));
    if (between >= totalMs) and (between < totalMs2) then
    begin
      Result := str;
      AProgress := (between - totalMs) * 1.0 / ms;
      break;
    end;
    totalMs := totalMs2;
  end;
end;

function tglobal.DownloadMp3(Source, Dest, realname: string): Boolean;
var
  lst: tstringlist;
  s: AnsiString;
begin
//  try
//    Result := UrlDownloadToFile(nil, pChar(Source), pChar(Dest), 0, nil) = 0;
//    if Result then
//    begin
//
//      lst := tstringlist.create;
//      if FileExists(appdir + 'playlist') then
//      begin
//        lst.LoadFromFile(appdir + 'playlist');
//      end;
//      s := realname + ',' + Dest;
//      lst.Add(s);
//      lst.SaveToFile(appdir + 'playlist');
//      lst.Free;
//
//    end;
//    Form1.Timer1.Enabled := False;
//    Form1.img_down.Picture.LoadFromFile(appdir + 'img\d1.png');
//    // 1,E:\umusic\umusic\1.mp3
//  except
//    Form1.Timer1.Enabled := False;
//    Result := False;
//  end;

end;

procedure tglobal.load_local_music;
var
  idx: Integer;
  arrs: TArray<string>;
begin

  local_playlst.Clear;
  if FileExists('playlist') then
    local_playlst.LoadFromFile('playlist');

  for idx := 0 to local_playlst.Count - 1 do
  begin
    arrs := local_playlst.Strings[idx].Split([',']);
    if not playDic.ContainsKey(arrs[0]) then
    begin
      playDic.Add(arrs[0], arrs[1]);
      frm_local.songlst.Items.Add(arrs[0]);
    end;
  end;
  if frm_local.songlst.Count > 0 then
    frm_local.songlst.Selected[0] := true;
end;

procedure tglobal.load_pause_img;
begin
  Form1.IMG_START.Picture.LoadFromFile(appdir + 'img\p1.png');

  Form1.IMG_START.Tag := 2;
end;

procedure tglobal.load_play_img;
begin
  Form1.IMG_START.Picture.LoadFromFile(appdir + 'img\p1.png');

end;

procedure tglobal.load_play_img_pause;
begin
  Form1.IMG_START.Picture.LoadFromFile(appdir + 'img\a1.png');

end;

const
  xTitleHeight: Integer = 1; // 标题栏的高度
  xFramWidth: Integer = 1; // 左、右、下边框的厚度

function tglobal.LocalMusic(song_file: AnsiString): Boolean;
begin

  freeStream(Stream);
  Result := true;
  if pos('http:', song_file) > 0 then
  begin
    try
      Stream := BASS_StreamCreateURL(PAnsiChar(song_file), 0, 0, nil, 0);
      if Stream = 0 then
      begin
        Result := False;
        Exit;
      end;

    except
      Result := False;
    end;
  end
  else
  begin
    try
      if not FileExists(song_file) then
      begin
        ShowMessage('音乐文件不存在');
        Exit;
      end;

      Stream := BASS_StreamCreateFile(False, PAnsiChar(song_file), 0, 0, 0);

      if Stream < BASS_ERROR_ENDED then
      begin
        Result := False;
        Exit;

      end;
    except
      Result := False;
    end;
  end;
  if Result then
  begin
    BASS_ChannelPlay(Stream, true);
    sum_time := Bass_ChannelBytes2Seconds(Stream, Bass_ChannelGetLength(Stream, BASS_POS_BYTE)); { 总秒数 }

    BASS_ChannelSetSync(Stream, BASS_SYNC_END, 0, @PlayFinishCallBack, nil);
    BASS_ChannelPlay(Stream, False);
  end;
end;

procedure tglobal.HIDE_DESKTOP_BTN;
begin
  Form1.IMG_START.Visible := False;
  Form1.IMG_next.Visible := False;
  Form1.img_list.Visible := False;

  Form1.IMG_START.Tag := 1;

end;

procedure tglobal.SHOW_DESKTOP_BTN;
begin
  Form1.IMG_START.Visible := true;
  Form1.IMG_START.BringToFront;
  Form1.IMG_next.Visible := true;
  Form1.IMG_next.BringToFront;
  Form1.img_list.Visible := true;
  Form1.img_list.BringToFront;



end;



procedure tglobal.textoutA(txt: string; canvas: tcanvas; x, y, fontsize: integer; r, g, b: byte);
var
  font: TGPFont;
  Pt: TGPPointF;
  StringFormat: TGPStringFormat;
  Brush: TGPSolidBrush;
  graphics: tGPGraphics;     //封装一个 GDI+ 绘图图面
begin

  graphics := TGPGraphics.Create(canvas.Handle);
  graphics.SetSmoothingMode(SmoothingModeAntiAlias); //指定平滑（抗锯齿）
  graphics.SetInterpolationMode(InterpolationModeHighQualityBicubic); //指定的高品质，双三次插值

  font := TGPFont.Create('微软雅黑', fontsize, 0);
  Brush := TGPSolidBrush.Create(MakeColor(155, r, g, b));
//     Brush := TGPSolidBrush.Create(MakeColor(r,g,b));
  StringFormat := TGPStringFormat.Create();

  Pt := MakePoint(x, y * 0.1 * 10);
  graphics.DrawString(txt, Length(txt), font, Pt, StringFormat, Brush);

  graphics.Free;
  font.Free;
  Brush.Free;
end;

procedure tglobal.textout(txt: string; canvas: tcanvas; x, y: integer; r, g, b: byte);
var
  graphics: tGPGraphics;     //封装一个 GDI+ 绘图图面
  fontFamily: tGPFontFamily; //定义有着相似的基本设计但在形式上有某些差异的一组字样
  path: tGPGraphicsPath;     //表示一系列相互连接的直线和曲线
  strFormat: tGPStringFormat; //封装文本布局信息，显示操作
  pen: tGPPen;     //定义用于绘制直线和曲线的对象
begin

  graphics := TGPGraphics.Create(canvas.Handle);
  graphics.SetSmoothingMode(SmoothingModeAntiAlias); //指定平滑（抗锯齿）
  graphics.SetInterpolationMode(InterpolationModeHighQualityBicubic); //指定的高品质，双三次插值
  fontFamily := TGPFontFamily.Create('微软雅黑'); //△字体，效果图为'微软雅黑'字体

  strFormat := TGPStringFormat.Create();
  path := TGPGraphicsPath.Create();



  //---------------------结束：初始化操作--------------------------------------
  path.AddString(txt, length(txt),        //要添加的 String
    fontFamily,       //表示绘制文本所用字体的名称
    0,                //指定应用到文本的字形信息,这里为普通文本
    80,               //限定字符的 Em（字体大小）方框的高度
    MakePoint(x, y), //一个 Point，它表示文本从其起始的点
    strFormat);       //指定文本格式设置信息

  pen := TGPPen.Create(MakeColor(155, r, g, b), 3);
  graphics.DrawPath(pen, path);    //初步绘制GraphicsPath

  graphics.Free;
  strFormat.Free;
  path.Free;

end;



procedure GetLyric2(FileName: string);
var
  lst: tstringlist;
  i: Integer;
begin

  lst := tstringlist.create();
  try
    lst.Text := FileName;

    lrclst.Clear;
    for i := 0 to lst.Count - 1 do
    begin
      if Copy(lst[i], 10, 1) <> ']' then
        Continue
      else if Copy(lst[i], 7, 1) <> '.' then
        Continue
      else if lst[i] <> '' then
      begin
        lrclst.Add(lst[i]);
      end;

    end;
  finally
    lst.Free;
  end;

end;

initialization
  g_lobal.g_song_index := -1;
  g_lobal.playflag := false;
  g_lobal.one := 0;

end.

