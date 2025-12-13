// unit PluginCtrl
//
// This unit takes charge of followings for TBASSPlayer
//  - managing Winamp plug-ins such as loading, unloading and launching plug-ins.
//  - interfacing Winamp input plug-in to BASS sound system.
//  - controlling BASS channels.
// BASS sound sytem acts like an output plug-in when the opened stream is being
// decoded by Winamp input plug-in in this unit.
// TBASSPlayer can play any types of stream files if you provide appropriate Winamp
// input plug-ins.
//
//
//       written by Silhwan Hyun  (hyunsh@hanafos.com)
//
// (vis plug-in = Winamp visualization plug-in)
// (vis window = the window used for visualization created by vis plug-in)
// (EMBED window = the window which serves vis plug-in with its client area for visualization)
//

//  Modified IPC message handling function WindowProc to support Winamp GPP.
//
// Ver 1.44                   1 Oct 2008
//  Renamed function (for VisDrawer.dll) names to differentiate them from the function's for
//   native Winamp GPP.
//    StartGPPModule -> RunVisDrawerModule
//    SetGPPInactive -> StopVisDrawerModule
//    GPPActive -> VisDrawerActive
//  Fixed following problems by modifing function omodWrite2
//   - out of sync at playing net radio (~.ASX)
//   - crash at freeing in-use BASS add-on
//  Changed the global procedure WinProcessMessages to local procedure because I am not sure
//   whether the procedure is safe at multi thread environment.
//   -> defined procedure WinProcessMessages per thread (or per unit) basis.
//  Changed function omodGetOutputTime, omodGetWrittenTime and GetPlayedTime to prevent floating
//   point exception.
//  Added an item "Format" in TStreamInfo, to put the information of stream format.
//  New message constants
//    - WM_ChannelUnavailable : to notify that Decode channel is unavailable.
//    - PlayListChange : to support Play List
//    - CheckTitleBar : to adjust the highlighted state of EMBED window
//
// (supplement at Ver 1.44.1)
//  Modified function WindowProc to drive multiple Winamp GPPs simultaneously.
//

// Ver 1.43                      15 Jul 2008
//  Added a function GetBufferAddress which renders the address of data buffer for rendering
//   visualization data
//  Modified function StartGPPModule to set initial vis window's size & position
//  Added a procedure SetChannelInfo2
//  Added a enum type : TPluginRequest
//  Added record types : TVisWindowIs
//  Modified & Renamed a record type : TVisDriveThreadInfo -> TVisPluginInfo
//  Added constants for the driver of vis plug-in : WM_RequestFromVis, UnloadVisPlugin
//
// Ver 1.42                       8 Dec 2006
//  Added functions and a procedure to support Winamp-like visualization window using the
//  customized general purpose plugin, 'Gen_VisDrawer.dll'.
//   function StartGPPModule, GPPActive
//   procedure SetGPPInactive
//  Added message constants : WM_GetLyric, WM_GetHTTPHeaders
//
// Ver 1.41                       25 Oct 2006
//   Some trivial changes such as comments, explanations
//
// Ver 1.40                        27 Feb 2005
//  Added 8 procedures/functions to support "dual channel mode".
//  Added function ActivePlugin to get active input plug-in's name.
//  Modified function SelectInputPlugin to enable to set the state indicating 'none of input
//   plug-ins is in use'.
//  Modified DSP plug-in related functions to prohibit duplicate running DSP plug-in.
//  Added function DSPBufferReady to inform you if DSP plug-in is applicable.
//  Removed function GetMsgHandler.
//  Removed function GetMainHandle.
//  Removed internal message handler. ( Internal messages are handled by main message handler
//   in BASSPlayer.pas to eliminate timing problems. )
//  Removed procedure SetMainHandle.
//  Added procedure SetReachedEnd to set the variable ReachedEnd at external routine.
//
// Ver 1.32                        7 Feb 2005
//  Modified some functions to adjust buffer (to hold decoded sound data) size if previously
//   allocated amount is out of reasonable range.
//  (Required to handle multi channel streams)
//  Added some functions to enhance stability at runnun DSP plug-ins.
//  Removed procedure SetSongDuration.
//
// Ver 1.31                       14 Dec 2004
//  Made some minor modifications for new BASS version (2.0 -> 2.1)
//
// Ver 1.3                         7 Feb 2004
//   Added procedure SetSongDuration
//   Added function IsWinampPluginLoaded
//
// Ver 1.2                        15 Dec 2003
//   Added procedures used by VisoutIntf.pas to correct errors at ending visualization
//   Added functions and a procedure for DSP plug-in
//   Added function GetPluginNumber to get the number of plug-in for specified file type
//
// Ver 1.1                        12 May 2003
//   Modified a procedure LoadVisModule (-> added a parameter "ParentHandle" )
//
// Ver 1.0                        30 Jan 2003
//   - Initial release
//

unit PluginCtrl;

{$DEFINE DEBUG}

interface

uses
   Windows, SysUtils, Messages, Forms, ioplug, Dynamic_BASS, wa_ipc, Graphics;

const
   WM_GetChannelData = WM_USER + 114;
   WM_ChannelUnavailable = WM_USER + 120;

   ChannelLimit = 8;
   maxDSPmodNum = 8;

   CLASSNAME_WINAMP : pchar = 'Winamp v1.x';

type
  TDSPmod = array[0..maxDSPmodNum-1] of PWinAmpDSPModule;

  function  omodWrite2 : integer;
  function  omodOpen2(D_Channel : DWORD;
                      samplerate, numchannels, bitspersamp : integer) : DWORD;
  procedure omodClose2;
  procedure ClearBuffer;
  function  DataInBuffer : DWORD;

  function  DSPBufferReady : boolean;
  function  DSPActive : boolean;
  procedure LoadDSPModule(PluginPath : WideString;
                          var DSPheader : PWinampDSPHeader;
                          var DSPmod : TDSPmod;
                          var NumDSPmod : integer);
  function  StartDSPModule(ModuleNum : word;
                          ParentHandle : HWND) : integer;
  function  StopDSPModule : integer;
  function  UnloadDSPModule : integer;

  function  InitPluginCtrl(ParentHandle: HWND) : boolean;
  procedure QuitPluginCtrl;

implementation



var
   pBuf : PBYTE;
   dummyBuf : PBYTE;
   bufSize : DWORD = 0;
   DSPBuffer : PBYTE;
   DSPBufferSize : DWORD = 0;
   omod : ^TOut_module;
   omodReady : boolean = false;

   PlayThreadId : DWORD = 0;
   CloseRequested : boolean;
   PlayThreadStarted : boolean;
   PlayChannel : HSTREAM = 0;
   DecodeChannel : DWORD;

   totalGet : int64;

   CurDSPmod  : TDSPmod;
   DSPmodNum : integer = 0;
   DSPmodIndex : integer;
   DSPIsActive : boolean = false;

   VisDrawerIsReady : boolean = false;

   hParentHandle : HWND;

   hFakeWindow : HWND = 0;

   WinampClassRegistered : boolean = false;

   PlayThreadHandle : HWND;

   IsStreamClosing : boolean;

   OrgWndProc : pointer;

procedure WinProcessMessages;
var
    ProcMsg  :  TMsg;
begin
    while PeekMessage(ProcMsg, 0, 0, 0, PM_REMOVE) do begin
      if (ProcMsg.Message = WM_QUIT) then Exit;
      TranslateMessage(ProcMsg);
      DispatchMessage(ProcMsg);
    end;
end;

procedure ShowErrorMsgBox(ErrorStr : string);
begin
   Application.MessageBox(PChar(ErrorStr), 'Error', MB_OK + MB_ICONERROR);
end;

//---------- procedures & functions to emulate Winamp output plug-in -----------

const
   PacketSize = 1152;
   WinampBaseSize = 576;
   DefaultBufSize = 88200;

var
   rOffset : dword;
   wOffset : dword;
   SPS : integer;
   BPS : integer;
   Channels : integer;
   BASSDataSize : dword;
   isReading : boolean;
   isWriting : boolean;
   InitialBufferFill : boolean;
   ReachedEnd : boolean;

function FreeSpace(BufferSize, ReadOffset, WriteOffset : dword) : dword;
begin
   if ReadOffset > WriteOffset then
      result := ReadOffset - WriteOffset
   else
      result := BufferSize  - WriteOffset + ReadOffset;
end;

function DataRemains(BufferSize, ReadOffset, WriteOffset : dword) : dword;
begin
   if ReadOffset > WriteOffset then
      result := BufferSize  + WriteOffset - ReadOffset
   else
      result := WriteOffset - ReadOffset;
end;


//------------------------ BASS dual channel mode support -----------------------

function omodWrite2 : integer;
var
   dw : dword;
   ReqSpace, RetSamples : dword;
   ReqSize, GetSize, RetSize : dword;
   p, p2 : pointer;
   ChannelStat : dword;
   wCycle : integer;
begin
   result := 1;

   if PlayChannel = 0 then
      exit;
   if ReachedEnd then
      exit;

   if isReading then
   begin
      wCycle := 0;
      repeat
         WinProcessMessages;
         sleep(20);
         inc(wCycle);
      until (not isReading) or (wCycle = 150);
   {$IFDEF DEBUG}
      if isReading then
         ShowErrorMsgBox('isReading is not cleared at function omodWrite2');
    {$ENDIF}
   end;

   isWriting := true;

   ReqSize := 576 * Channels;
   if BPS > 8 then
      ReqSize := ReqSize * 2;
   if SPS > 22050 then
      ReqSize := ReqSize * 2;
   if DSPIsActive then
      ReqSpace := ReqSize * 2
   else
      ReqSpace := ReqSize;

   if FreeSpace(bufSize, rOffset, wOffset) < ReqSpace then
   begin
      isWriting := false;
      exit;
   end;

   GetSize := BASS_ChannelGetData(DecodeChannel, DSPBuffer, ReqSize);

   if GetSize = DWORD(-1) then
   begin
      ReachedEnd := true;
      isWriting := false;
      if BASS_ErrorGetCode = BASS_ERROR_HANDLE then
         if (not IsStreamClosing) then
            result := -1;
      exit;
   end;

   if GetSize > 0 then
   begin
      inc(totalGet, GetSize);

      if DSPIsActive then
      begin
         try
           RetSamples := CurDSPmod[DSPmodIndex].ModifySamples(CurDSPmod[DSPmodIndex],
                                      DSPBuffer, GetSize div DWord((Channels * 2)),
                                      BPS, DWord(Channels), SPS);
         except
           ShowErrorMsgBox('DSP error');
           RetSamples := 0;
         end;
         RetSize := RetSamples * DWord((BPS div 8)) * DWORD(Channels);
      end else
         RetSize := GetSize;

      dw := dword(pBuf) + wOffset;
      p := pointer(dw);

      if rOffset > wOffset then
      begin
         Move(DSPBuffer^, p^, RetSize);
         inc(wOffset, RetSize);
      end
      else
         if (bufSize - wOffset) > RetSize then
         begin
            Move(DSPBuffer^, p^, RetSize);
            inc(wOffset, RetSize);
         end else
         begin
            Move(DSPBuffer^, p^, bufSize - wOffset);
            if (bufSize - wOffset) < RetSize then
            begin
               dw := dword(DSPBuffer) + (bufSize - wOffset);
               p2 := pointer(dw);
               Move(p2^, pBuf^, RetSize - (bufSize - wOffset));
            end;
            wOffset := RetSize - (bufSize - wOffset);
         end;
   end else
   begin
      ReachedEnd := true;
      isWriting := false;
      exit;
   end;

   if GetSize < ReqSize then
      ReachedEnd := true
   else begin
      if PlayChannel <> 0 then
      begin
         ChannelStat := BASS_ChannelIsActive(PlayChannel);
         if InitialBufferFill or (ChannelStat = BASS_ACTIVE_PLAYING) or
                                         (ChannelStat = BASS_ACTIVE_STALLED) then
            if FreeSpace(bufSize, rOffset, wOffset) > ReqSpace then
               PostThreadMessage(PlayThreadId, WM_GetChannelData, 0, 0);
      end;
      result := 0;
   end;

   if InitialBufferFill then
      if (FreeSpace(bufSize, rOffset, wOffset) <= ReqSpace) or
         (DataRemains(bufSize, rOffset, wOffset) >= (BASSDataSize SHL 1)) then
         InitialBufferFill := false;

   isWriting := false;
end;

function GetResampledData(handle: HSTREAM; buf: Pointer; len, user: DWORD): DWORD; stdcall;
var
   dw : DWORD;
   p, p2 : pointer;
   wCycle : integer;
begin
   if InitialBufferFill then
   begin
      PostThreadMessage(PlayThreadId, WM_GetChannelData, 0, 0);
      repeat
         WinProcessMessages;
         Sleep(20);
         if ReachedEnd then
            break;
      until (InitialBufferFill = false);
   end;

   if isWriting then
   begin
      wCycle := 0;
      repeat
         WinProcessMessages;
         sleep(20);
         inc(wCycle);
      until (not isWriting) or (wCycle = 150);
   {$IFDEF DEBUG}
      if isWriting then
         ShowErrorMsgBox('isWriting is not cleared at function GetResampledData');
    {$ENDIF}
   end;

   isReading := true;

   dw := dword(pBuf) + rOffset;
   p := pointer(dw);

   if rOffset > wOffset then
      if (bufSize - rOffset) > len then
      begin
         Move(p^, buf^, len);
         inc(rOffset, len);
         result := len;
      end else
      begin
         Move(p^, buf^, bufSize - rOffset);
         if (bufSize - rOffset) < len then
         begin
            dw := dword(buf) + bufSize - rOffset;
            p2 := pointer(dw);
            if (len - (bufSize - rOffset)) < wOffset then
            begin
               Move(pBuf^, p2^, len - (bufSize - rOffset));
               rOffset := len - (bufSize - rOffset);
               result := len;
            end else
            begin
               Move(pBuf^, p2^, wOffset);
               rOffset := wOffset;
               result := bufSize - rOffset + wOffset;
            end;
         end else
         begin
            rOffset := 0;
            result := len;
         end;
      end
   else if rOffset < wOffset then
      if (wOffset - rOffset) >= len then
      begin
         Move(p^, buf^, len);
         inc(rOffset, len);
         result := len;
      end else
      begin
         Move(p^, buf^, wOffset - rOffset);
         result := wOffset - rOffset;
         rOffset := wOffset;
      end
   else
      result := 0;

   if result < len then
      if ReachedEnd then
         result := result + BASS_STREAMPROC_END
      else
         PostThreadMessage(PlayThreadId, WM_GetChannelData, 0, 0)
   else
      PostThreadMessage(PlayThreadId, WM_GetChannelData, 0, 0);

   isReading := false;
end;

procedure ClearBuffer;
begin
   rOffset := 0;
   wOffset := 0;
   totalGet := 0;
   isWriting := false;
   InitialBufferFill := true;
   ReachedEnd := false;
end;

function PlayNewThread(lpParam : pointer) : DWORD; stdcall;
var
   Msg : TMsg;
   MsgReturn : longbool;
begin
   CloseRequested := false;
   PlayThreadStarted := true;
   SetThreadPriority(GetCurrentThread, THREAD_PRIORITY_ABOVE_NORMAL);

   repeat
         MsgReturn := GetMessage(Msg, 0, 0, 0);
         if ((Msg.message = WM_QUIT) or (Msg.message = WM_CLOSE)) then
             CloseRequested := true
         else if Msg.message = WM_GetChannelData then
            if PlayChannel <> 0 then
               if not isWriting then
                  if omodWrite2 = -1 then
                     PostMessage(hParentHandle, WM_ChannelUnavailable, 0, 0);

         TranslateMessage(Msg);
         DispatchMessage(Msg);
   until (integer(MsgReturn) <= 0) or (PlayChannel = 0) or CloseRequested;

   Result := 0;
   PlayThreadId := 0;
   ExitThread(0);
end;

function omodOpen2(D_Channel : DWORD;
                   samplerate, numchannels, bitspersamp : integer) : DWORD;
var
   flags : DWORD;

begin
   result := 0;

   IsStreamClosing := false;

   if bitspersamp = 8 then
      flags := BASS_SAMPLE_8BITS
   else
      flags := 0;

   PlayChannel := BASS_StreamCreate(samplerate,
                                    numchannels,
                                    flags,
                                    @GetResampledData,
                                    nil);

   if PlayChannel <> 0 then
   begin
      SPS := samplerate;
      BPS := bitspersamp;
      Channels := numchannels;
      BASSDataSize := (SPS * (BPS div 8) * CHANNELS * 2) div 10;

      if ((BASSDataSize * 2) > bufSize) or ((BASSDataSize * 4) < bufSize) then
      begin
         if (pBuf <> nil) then
            FreeMem(pBuf);
         pBuf := nil;
         bufSize := 0;
         GetMem(pBuf, BASSDataSize * 3);
         if (pBuf <> nil) then
            bufSize := BASSDataSize * 3
         else begin
            BASS_StreamFree(PlayChannel);
            exit;
         end;
      end;

      DecodeChannel := D_Channel;

      ClearBuffer;
      PlayThreadStarted := false;
      PlayThreadHandle := CreateThread(nil, 0, @PlayNewThread, nil, 0, PlayThreadId);

      if PlayThreadHandle <> 0 then
      begin
        repeat
           WinProcessMessages;
           Sleep(20);
        until PlayThreadStarted;

        result := PlayChannel;
      end else begin
         BASS_StreamFree(PlayChannel);
         ShowErrorMsgBox('Unable to create Play Thread.');
      end;
   end;
end;

procedure omodClose2;
begin
   IsStreamClosing := true;

   if PlayChannel <> 0 then
   begin
      BASS_StreamFree(PlayChannel);
      PlayChannel := 0;
   end;

   if (PlayThreadId <> 0) then
   begin
      PostThreadMessage(PlayThreadId, WM_CLOSE, 0, 0);

      repeat
         WinProcessMessages;
         sleep(20);
      until PlayThreadId = 0;

      CloseHandle(PlayThreadHandle);
   end;
end;

function DataInBuffer : DWORD;
begin
   result := DataRemains(bufSize, rOffset, wOffset);
end;


//------------------------- Winamp DSP plug-in support ---------------------------

function WindowProc(hWnd, Msg, wParam, lParam : Longint) : Longint; stdcall;
var
   TitleP : pchar;
   FileP : pchar;
begin
   Result := 0;

   if Msg = WM_WA_IPC then
   begin
     if lParam = IPC_GETVERSION then
        Result := $2041
     else   if LParam = IPC_GETWND then
     begin
        if WParam = IPC_GETWND_PE then
           result := hFakeWindow;
     end;
   end else
      Result := DefWindowProc(hWnd, Msg, wParam, lParam);

end;

function CreateFakeWindow(ParentWindow : HWND) : HWND;
var
   hInst  : HWND;
   WinAtom : TAtom;
   wClass : TWNDCLASSEX;
begin
   result := 0;

   if hFakeWindow <> 0 then
   begin
      result := hFakeWindow;
      exit;
   end;

   hInst := GetModuleHandle(nil);

   if not WinampClassRegistered then
   begin
     with wClass do
     begin
       cbSize        := sizeof(wClass);
       Style         := CS_PARENTDC;
       lpfnWndProc   := @WindowProc;
       cbClsExtra    := 0;
       cbWndExtra    := 0;
       hInstance     := hInst;
       hIcon         := 0;
       hCursor       := LoadCursor(0, IDC_ARROW);
       hbrBackground := COLOR_BTNFACE + 1;
       lpszMenuName  := nil;
       lpszClassName := CLASSNAME_WINAMP;
       hIconSm       := 0;
     end;

     WinAtom := windows.RegisterClassEx(wClass);

     if WinAtom <> 0 then
        WinampClassRegistered := true;

   end;

   if WinampClassRegistered then
      result := CreateWindowEx(0, CLASSNAME_WINAMP, 'Winamp 2.41',
                                    WS_POPUP,
                                    5, 5, 25, 25,
                                    ParentWindow, 0, hInst, nil);
end;

function DestroyFakeWindow : boolean;
begin
   if hFakeWindow <> 0 then
      if IsWindow(hFakeWindow) then
      begin
        try
          result := DestroyWindow(hFakeWindow);
        except
          result := false;
        end;

        if result then
        begin
          hFakeWindow := 0;
        end;
      end else
         result := false
   else
      result := false
end;

function DSPBufferReady : boolean;
begin
   result := (DSPBufferSize <> 0);
end;

function DSPActive : boolean;
begin
   result := DSPIsActive;
end;

procedure LoadDSPModule(PluginPath : WideString;
                        var DSPheader : PWinampDSPHeader;
                        var DSPmod : TDSPmod;
                        var NumDSPmod : integer);
var
   i : integer;
begin
   NumDSPmod := 0;

   if not WideSameText(PluginPath,GetLoadedDSPDLL) then
   begin
      DSPmodIndex := -1;
      DSPmodNum := 0;
      if not initDSPDll(PluginPath) then
         exit;
   end else if DSPmodNum > 0 then
   begin
      DSPheader := getDSPHeader;
      DSPmod := CurDSPmod;
      NumDSPmod := DSPmodNum;
      exit;
   end;

   DSPheader := getDSPHeader;
   if DSPHeader = nil then
     exit;

   for i := 0 to (maxDSPmodNum - 1) do
   begin
      DSPmod[i] := DSPheader.getModule(i);
      if DSPmod[i] <> nil then
      begin
         DSPmod[i]^.hDllInstance := GetDSPDLLHandle;
         inc(DSPmodNum);
      end else
         break;
   end;

   CurDSPmod := DSPmod;
   NumDSPmod := DSPmodNum;
end;


function StartDSPModule(ModuleNum : word;
                        ParentHandle : HWND) : integer;
begin
   result := -1;

   if DSPBufferSize = 0 then
      exit;
   if hFakeWindow = 0 then
      exit;
   if DSPmodNum = 0 then
      exit;
   if ModuleNum > (DSPmodNum - 1) then
      exit;

   if DSPmodIndex = ModuleNum then
   begin
      result := 0;
      exit;
   end;

   if DSPmodIndex > -1 then
      if CurDSPmod[DSPmodIndex] <> nil then
         CurDSPmod[DSPmodIndex]^.Quit(CurDSPmod[DSPmodIndex]);

   CurDSPmod[ModuleNum]^.hwndParent := hFakeWindow;
   DSPIsActive := (CurDSPmod[ModuleNum]^.init(CurDSPmod[ModuleNum]) = 0);
   if DSPIsActive then
   begin
      DSPmodIndex := ModuleNum;
      result := 0;
   end;
end;

function StopDSPModule : integer;
begin
   result := -1;
   if DSPmodNum = 0 then
      exit;

   if DSPIsActive then
   begin
      DSPIsActive := false;
      if CurDSPmod[DSPmodIndex] <> nil then
         CurDSPmod[DSPmodIndex]^.Quit(CurDSPmod[DSPmodIndex]);
   end;

   DSPmodIndex := -1;

   result := 0;
end;

function UnloadDSPModule : integer;
begin
   if StopDSPModule = 0 then
   begin
      CloseDSPDLL;
      DSPmodNum := 0;
      result := 0;
   end else
      result := -1;
end;


// initialization
function InitPluginCtrl(ParentHandle: HWND) : boolean;
begin
   if omodReady then
   begin
      result := true;
      exit;
   end;

   result := false;
   hParentHandle := ParentHandle;

   try
     GetMem(pBuf, DefaultBufSize);
     GetMem(dummyBuf, 4608);
     bufSize := DefaultBufSize;
   except
     exit;
   end;

   FillChar(dummyBuf^, SizeOf(dummyBuf), #0);

   if bufSize > 0 then
     try
       GetMem(DSPBuffer, ChannelLimit * PacketSize * 4);
       DSPBufferSize := ChannelLimit * PacketSize * 4
     except
       exit;
     end;

   hFakeWindow := CreateFakeWindow(ParentHandle);
   if hFakeWindow <> 0 then
      OrgWndProc := Pointer(GetWindowLong(hFakeWindow, GWL_WNDPROC));

   omodReady:=True;
   result := omodReady;
end;

// finalization
procedure QuitPluginCtrl;
begin
   if (omod <> nil) then
      omod.Quit;

   if (pBuf <> nil) then
   begin
      FreeMem(pBuf);
      bufSize := 0;
   end;
   if dummyBuf <> nil then
      FreeMem(dummyBuf);

   if (DSPBuffer <> nil) then
   begin
      FreeMem(DSPBuffer);
      DSPBufferSize := 0;
   end;

   if hFakeWindow <> 0 then
   begin
      if GetWindowLong(hFakeWindow, GWL_WNDPROC) <> LongInt(OrgWndProc) then
         SetWindowLong(hFakeWindow, GWL_WNDPROC, LongInt(OrgWndProc));
      DestroyFakeWindow;
   end;
end;

end.
