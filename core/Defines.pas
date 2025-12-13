unit Defines;

interface

uses
  Winapi.Windows, System.Classes, Winapi.Messages, System.SysUtils,
  System.Variants, System.StrUtils, Winapi.CommCtrl, Vcl.Graphics;

type
  { 媒体状态 }
  TMediaState = (msStopped, msPlaying, msStalled, msPaused);

  { 播放表列链表 }
  PPlayList = ^TPlayList;
  TPlayList = record
    Caption  : string;          // 歌曲名
    Singer   : string;          // 歌手
    Length   : Integer;         // 歌曲长度
    LastPlayPosition : Integer; // 上一次播放位置
    Lyric    : string;          // 歌词文件
    FileName : string;          // 歌曲文件名
  end;

const
   { 加载皮肤时的 }
   ControlList: array[0..17] of string =
                   (
                     'play',        {00}
                     'pause',       {01}
                     'next',        {02}
                     'prev',        {03}
                     'close',       {04}
                     'minimode',    {05}
                     'minsize',     {06}
                     'mainmenu',    {07}
                     'gradient',    {08}
                     'split',       {09}
                     'volume',      {10}
                     'progress_bkg',{11}
                     'progress',    {12}
                     'progress_btn',{13}
                     'album_bkg',   {14}
                     'back',        {15}
                     'album',       {16}
                     'timelabel'    {17}
                   );

   { 控件属性列表 }
   ControlPropertys:array[0..10] of string =
                   (
                    'Left',      {00}
                    'Top',       {01}
                    'Width',     {02}
                    'Height',    {03}
                    'Enabled',   {04}
                    'Visible' ,  {05}
                    'ShowHint' , {06}
                    'Hint',      {07}
                    'GlyphCount',{08}
                    'FileName',  {09}
                    'AutoSize'   {10}
                    );


   { 可有事件的控件名称 }
   ControlName  : array[0..10] of string =
                   (
                    'PngBtn_play' ,        {00}
                    'PngBtn_pause',        {01}
                    'PngBtn_next',         {02}
                    'PngBtn_prev',         {03}
                    'PngBtn_close',        {04}
                    'PngBtn_minsize',      {05}
                    'PngBtn_minimode',     {06}
                    'PngBtn_mainmenu',     {07}
                    'PngBtn_volume',       {08}
                    'PngBtn_progress_btn', {09}
                    'PngBtn_back'          {10}
                    );

   { 媒体的通知消息 }
   { 自定义通知道消息 }
   { PostMessage(Handle, MEDIA_NOTIFY, MEDIA_NOTIFY_SELECT, 1)
     表示通知主窗口这边列表框已经双击选播放当前}
   { Message }
   MEDIA_NOTIFY = WM_USER + 30;
   { wParam }
   //MEDIA_NOTIFY_PLAY  = 0;  // 通知播放
   //MEDIA_NOTIFY_STOP  = 1;  // 通知停止
   //MEDIA_NOTIFY_PAUSE = 2;  // 通知暂停
   MEDIA_NOTIFY_NEXT   = 3;   // 通知下一曲
   MEDIA_NOTIFY_PREV   = 4;   // 通知上一曲
   MEDIA_NOTIFY_SELECT = 5;   // 通知播放当前选择
   

  { 根据属性名返回索引判断 }
  function GetPropertyIndexByName(Name: string):Integer;
  { 根据类名返回类型索引 }
  function GetNameIndexByName(Name: string):Integer;
  function GetIndexByNodeName(NodeName: string):Integer;
  { 公用 }
  function CommonIndexByArray(Args: array of string; CmpName:string):Integer;


  function CheckOleValueToString(Value: OleVariant):String;
  function CheckOleValueToInteger(Value: OleVariant):Integer;
  function CheckOleValueToBoolean(Value: OleVariant):Boolean;

  procedure DbgStr(s:string; Args:array of const);
  function MediaLengthToTime(Len: Integer):String;
  function GetShortName(FileName:string; NewExt: string):string;

  function GetMediaFileNameInfo(FileName:string; var SongName, Singer: string):Boolean;


  function GetSubItemRect(hWd: HWND; Index, SubIndex: Integer): TRect;
  function GetColWidth(hWd: HWND; ColIndex: Integer): Integer;
  function GetStrWidth(hWd: HWND; s: string): Integer;
  function RGBToTColor2(RGBColor: Cardinal):TColor;

  function IsWindow7:Boolean;
  function URLEnCode(s: PAnsiChar; IsUtf8: Boolean = False):string;
  function StringHeight(DC: HDC; Text: string):Integer;
  function StringWidth(DC: HDC; Text: string):Integer;

implementation


function CommonIndexByArray(Args: array of string; CmpName:string):Integer;
var
  I:Integer;
begin
  Result := -1;
  if CmpName <> '' then
    for I := 0 to High(Args) do
    begin
      if Args[I] = CmpName then
      begin
        Result := I;
        Exit;
      end;  
    end;
end;  

function GetPropertyIndexByName(Name: string):Integer;
begin
  Result := CommonIndexByArray(ControlPropertys, Name);
end;

function GetNameIndexByName(Name: string):Integer;
begin
  Result := CommonIndexByArray(ControlName, Name);
end;  

function GetIndexByNodeName(NodeName: string):Integer;
begin
  Result := CommonIndexByArray(ControlList, NodeName);
end;  


function CheckOleValueToString(Value: OleVariant):String;
begin
  if Value = NULL then Result := '' else Result := Value;
end;

function CheckOleValueToInteger(Value: OleVariant):Integer;
begin
  if Value = NULL then Result := 0 else Result := Value;
end;

function CheckOleValueToBoolean(Value: OleVariant):Boolean;
begin
  if Value = NULL then Result := False else Result := Value;
end;

procedure DbgStr(s:string; Args:array of const);
begin
  OutputDebugString(PChar(Format(s, Args)));
end;  

function MediaLengthToTime(Len: Integer):String;
begin
  Result :=  RightStr('00' + IntToStr(Trunc(Len / 1000) div 60), 2) + ':' +
             RightStr('00' + IntToStr(Trunc(Len / 1000) mod 60), 2)
end;

function GetShortName(FileName:string; NewExt: string):string;
var
  s1, s2:string;
begin
   s1 := ExtractFileName(FileName);
   s2 := ExtractFileExt(s1);
   Result :=Copy(s1, 1, Length(s1) - Length(s2)) + NewExt;
end;

function GetMediaFileNameInfo(FileName:string; var SongName, Singer: string):Boolean;
var
  F:TStringList;
  s:string;
begin
  Result := False;
  F := TStringList.Create;
  s := GetShortName(FileName, '');
  ExtractStrings(['-'], [' '], PChar(s), F);
  if F.Count >= 2 then
  begin
     SongName := Trim(F[1]); Singer := Trim(F[0]);
  end else begin SongName := s; Singer := s; end;
  F.Free;
end;


function StringExtent(DC: HDC; const Text: string): TSize;
begin
  Result.cX := 0;
  Result.cY := 0;
  Winapi.Windows.GetTextExtentPoint32(DC, Text, Length(Text), Result);
end;

function StringWidth(DC: HDC; Text: string):Integer;
begin
  Result := StringExtent(DC, Text).cx;
end;

function StringHeight(DC: HDC; Text: string):Integer;
begin
  Result := StringExtent(DC, Text).cy;
end;

//======================================================================
// 取Item宽度

function GetSubItemRect(hWd: HWND; Index, SubIndex: Integer): TRect;
begin
  ListView_GetSubItemRect(hWd, Index, SubIndex, LVIR_LABEL, @Result);
end;
// 取柱头宽度

function GetColWidth(hWd: HWND; ColIndex: Integer): Integer;
begin
  Result := ListView_GetColumnWidth(hWd, ColIndex);
end;
// 取文字宽度

function GetStrWidth(hWd: HWND; s: string): Integer;
begin
  Result := ListView_GetStringWidth(hWd, PChar(s));
end;


function RGBToTColor2(RGBColor: Cardinal):TColor;
var
  ColorArr:array[0..3] of Byte;
begin
  ColorArr[0] := RGBColor shr 16;
  ColorArr[1] := RGBColor shr 8;
  ColorArr[2] := Byte(RGBColor);
  ColorArr[3] := 0;
  Result := TCOLOR(ColorArr);
end;

function IsWindow7:Boolean;
begin
  Result := ((TOSVersion.Major >= 6) and (TOSVersion.Minor >= 1));
end;


function URLEnCode(s: PAnsiChar; IsUtf8: Boolean):string;
var
  I:Integer;
  tmpstr:PAnsiChar;
begin
  if s = '' then  Exit('');
  if IsUtf8  then tmpstr := PAnsiChar(AnsiToUtf8(s)) else tmpstr := s;
  
  for I := 0 to Length(tmpstr) do
  begin
    if Ord(tmpstr[I]) >= 127 then
      Result := Result + '%' + IntToHex(Ord(tmpstr[I]), 2)
    else
      Result := Result + tmpstr[I];
  end;
end;

end.
