unit UrlSongs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.ExtCtrls, System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent;

type
  Tfrm_url = class(TForm)
    songlst: TListBox;
    Timer1: TTimer;
    NetHTTPClient1: TNetHTTPClient;
    procedure songlstDblClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    unit1handle: thandle;
  end;

var
  frm_url: Tfrm_url;

implementation

{$R *.dfm}

uses
  core;

procedure Tfrm_url.FormCreate(Sender: TObject);
begin
  Self.DoubleBuffered := True;
  songlst.DoubleBuffered := true;
end;

procedure Tfrm_url.FormPaint(Sender: TObject);
var
  hr: Cardinal;
begin
  hr := createroundrectrgn(1, 1, Width - 2, Height - 2, 5, 5);
  setwindowrgn(Handle, hr, True);
end;

procedure Tfrm_url.songlstDblClick(Sender: TObject);
begin
  jpgtag := 0;
  if (g_song_Info_list.Items[songlst.ItemIndex].songPicRadio <> 'null') and (g_song_Info_list.Items[songlst.ItemIndex].songPicRadio.Trim <> '') then
  begin
    try
      g_lobal.g_song_index := songlst.ItemIndex;
      jpgtag := 1;
      urlPlayFlag := true;
      sendmessage(unit1handle, wm_me, 0, 0);
    except
    end;
  end
  else
  begin
    jpgtag := 0;
  end;
  g_lobal.one := 0;
  //

end;

procedure Tfrm_url.Timer1Timer(Sender: TObject);
var
  lp: tpoint;
begin
  if frm_url.Visible = true then
  begin
    GetCursorPos(lp);
    if PtInRect(self.BoundsRect, lp) then
      songlst.SetFocus;
  end;
end;

end.

