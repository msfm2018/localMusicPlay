program Project1;

uses
  Vcl.Forms,   SysUtils,
  windows,
  Unit1 in 'Unit1.pas' {Form1},
  bass in 'bass.pas',
  ColorFrame in 'ColorFrame.pas',
  Vcl.Themes,
  Vcl.Styles,
  PluginCtrl in 'PluginCtrl.pas',
  SuperObject in 'SuperObject.pas',
//  u_debug in 'u_debug.pas',
  UrlSongs in 'UrlSongs.pas' {frm_url},
  core in 'core.pas',
  localSongs in 'localSongs.pas' {frm_local},
  Defines in 'core\Defines.pas',
  GDILyrics in 'core\GDILyrics.pas',
  ULrcShow in 'core\ULrcShow.pas' {frmLrcShow};

{$R *.res}
  const
  myatom = 'g_umusic_1';
begin
// if (GlobalFindAtom(myatom) = 0)  then
//  begin
//    GlobalAddAtom(myatom);
  Application.Initialize;

  // ¸ß DPI Ö§³Ö£¨Per Monitor V2£©
  if not TOSVersion.Check(10) or (TOSVersion.Build < 15063) then
    SetProcessDPIAware ;

    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);


  Application.MainFormOnTaskbar := True;
//  TStyleManager.TrySetStyle('Light');
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(Tfrm_url, frm_url);
  Application.CreateForm(Tfrm_local, frm_local);
  Application.CreateForm(TfrmLrcShow, frmLrcShow);
  Application.Run;
//   GlobalDeleteAtom(GlobalFindAtom(myatom));
//  end;
end.
