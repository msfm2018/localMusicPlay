unit Animation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.WinXCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.StdCtrls;

type
  TAnimation_ = class(TForm)
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Animation_: TAnimation_;

implementation

{$R *.dfm}

procedure TAnimation_.Timer1Timer(Sender: TObject);
begin
ProgressBar1.Position:=   ProgressBar1.Position+1;
end;

end.
