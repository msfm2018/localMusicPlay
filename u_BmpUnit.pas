unit u_BmpUnit;

interface
uses
  Windows,SysUtils, Classes,Graphics;


procedure MakeBmp(BmpIn: Graphics.TBitmap; var AverageColor: TColorRef);
implementation  

procedure FillSolidRect(m_hDC: HDC; lpRect: PRect; clr: COLORREF); overload;
begin
  Windows.SetBkColor(m_hDC, clr);
  Windows.ExtTextOut(m_hDC, 0, 0, ETO_OPAQUE, lpRect, nil, 0, nil);
end;

procedure FillSolidRect(m_hDC: HDC; x, y, cx, cy: Integer; clr: COLORREF); overload;
var
  r: TRect;
begin
  Windows.SetBkColor(m_hDC, clr);
  r := Rect(x, y, x + cx, y + cy);
  Windows.ExtTextOut(m_hDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
end;

const
  m_nOverRegio: integer = 100; //过度的大小

procedure DrawBKImageCross(dc, dcTemp: HDC; nWidth, nHeight: integer; clrCustomBK: TColorRef);
var
  blend: TBlendFunction;
  nStartX, nStartY: integer;
  i, j: integer;
  dRadiusTemp2: Double;
begin

  FillChar(blend, sizeof(blend), 0);
  blend.BlendOp := AC_SRC_OVER;
  blend.SourceConstantAlpha := 255;

  nStartX := nWidth - m_nOverRegio;
  nStartY := nHeight - m_nOverRegio;

  FillSolidRect(dc, nStartX, nStartY, m_nOverRegio, m_nOverRegio, clrCustomBK);
  for i := 0 to m_nOverRegio - 1 do
  begin
    for j := 0 to m_nOverRegio - 1 do
    begin
      dRadiusTemp2 := sqrt((i * i + j * j));
      if (dRadiusTemp2 > 99) then
      begin
        dRadiusTemp2 := 99;
      end;
      blend.SourceConstantAlpha := 255 - Round(2.55 * ((dRadiusTemp2 / m_nOverRegio) * 100));
      Windows.AlphaBlend(dc, nStartX + i, nStartY + j, 1, 1, dcTemp, nStartX + i, nStartY + j, 1, 1, blend);
    end;
  end;
end;

function DrawVerticalTransition(dcDes, dcSrc: hdc; const rc: TRect; nBeginTransparent: integer = 0; nEndTransparent: integer = 100): integer;
var
  bIsDownTransition: Boolean;
  nTemp: integer;
  blend: TBlendFunction;
  nStartPosition, nWidth, nHeight, nMinTransition, nMaxTransition: integer;
  dTransition: Double;
  i: integer;
begin
  bIsDownTransition := True;
  if (nEndTransparent <= nBeginTransparent) then
  begin
    bIsDownTransition := FALSE;
    nTemp := nBeginTransparent;
    nBeginTransparent := nEndTransparent;
    nEndTransparent := nTemp;
  end;

  FillChar(blend, sizeof(blend), 0);
  blend.BlendOp := AC_SRC_OVER;
  blend.SourceConstantAlpha := 255;

  nStartPosition := rc.top;
  nWidth := rc.right - rc.left;
  nHeight := rc.bottom - rc.top;

  nMinTransition := 255 - 255 * nBeginTransparent div 100;
  nMaxTransition := 255 * (100 - nEndTransparent) div 100;
  dTransition := (nMinTransition - nMaxTransition) / nHeight;
  if (bIsDownTransition) then
  begin
    for i := 0 to nHeight - 1 do
    begin
      blend.SourceConstantAlpha := nMinTransition - Round(dTransition * i);
      Windows.AlphaBlend(dcDes, rc.left, nStartPosition + i, nWidth, 1,
        dcSrc, rc.left, nStartPosition + i, nWidth, 1, blend);
    end;
  end
  else
  begin
    for i := 0 to nHeight - 1 do
    begin
      blend.SourceConstantAlpha := nMaxTransition + Round(dTransition * i);
      Windows.AlphaBlend(dcDes, rc.left, nStartPosition + i, nWidth, 1,
        dcSrc, rc.left, nStartPosition + i, nWidth, 1, blend);
    end;
  end;
  Result := blend.SourceConstantAlpha;
end;

procedure BlendBmp(BmpFrom, BmpTo: TBitmap; var Bmp: TBitmap; BlendValue: Byte);
var
  I, J: Integer;
  P, PFrom, PTo: PByteArray;
begin
  BmpFrom.PixelFormat := pf24bit;
  BmpTo.PixelFormat := pf24bit;
  Bmp.PixelFormat := pf24Bit;
  for J := 0 to Bmp.Height - 1 do
  begin
    P := Bmp.ScanLine[J];
    PFrom := BmpFrom.ScanLine[J];
    PTo := BmpTo.ScanLine[J];
    for I := 0 to Bmp.Width * 3 - 1 do
      P[I] := PFrom[I] * (255 - BlendValue) div 255 + PTo[I] * BlendValue div 255;
  end;
end;

procedure MakeBmp(BmpIn: Graphics.TBitmap; var AverageColor: TColorRef);
var
  BmpOut: Graphics.TBitmap;
  x, y: Integer;
  P: PRGBTriple;
  r, g, b: Integer;
  n: integer;
  nStartPosition: integer;
  i: integer;
  blend: TBlendFunction;
  rcTemp: TRect;
begin
  BmpIn.PixelFormat := pf24bit;
  BmpOut:=TBitmap.Create;

  //计算平均颜色
  r := 0; g := 0; b := 0;
  with BmpIn do
  begin
    for y := 0 to Height - 1 do
    begin
      P := BmpIn.ScanLine[y];
      for x := 0 to Width - 1 do
      begin
        r := r + P^.rgbtRed;
        g := g + P^.rgbtGreen;
        b := b + P^.rgbtBlue;
        Inc(P); //指向下一个像素
      end;
    end;
  end;
  n := BmpIn.Width * BmpIn.Height;
  AverageColor := RGB(r div n, g div n, b div n);

  BmpOut.Width := BmpIn.Width;
  BmpOut.Height := BmpIn.Height;


  //左上
  nStartPosition := BmpIn.Width - m_nOverRegio;
  BitBlt(BmpOut.Canvas.Handle, 0, 0, nStartPosition, BmpIn.Height - m_nOverRegio, BmpIn.Canvas.Handle, 0, 0, SRCCOPY);

  //上中
  FillSolidRect(BmpOut.Canvas.Handle, nStartPosition, 0, m_nOverRegio, BmpIn.Height - m_nOverRegio, AverageColor);

   //下中
  nStartPosition := BmpIn.Height - m_nOverRegio;
  FillSolidRect(BmpOut.Canvas.Handle, 0, nStartPosition, BmpIn.Width - m_nOverRegio, m_nOverRegio, AverageColor);

   //中间
  DrawBKImageCross(BmpOut.Canvas.Handle, BmpIn.Canvas.Handle, BmpIn.Width, BmpIn.Height, AverageColor);

  FillChar(blend, sizeof(blend), 0);
  blend.BlendOp := AC_SRC_OVER;
  blend.SourceConstantAlpha := 255; // 透明度

  //上中
  nStartPosition := BmpIn.Width - m_nOverRegio;
  for i := 0 to m_nOverRegio - 1 do
  begin
    blend.SourceConstantAlpha := 255 - Round(2.55 * i);
    Windows.AlphaBlend(BmpOut.Canvas.Handle, nStartPosition + i, 0, 1, BmpIn.Height - m_nOverRegio,
      BmpIn.Canvas.Handle, nStartPosition + i, 0, 1, BmpIn.Height - m_nOverRegio, blend);
  end;

  //下中
  rcTemp := Rect(0, BmpIn.Height - m_nOverRegio, BmpIn.Width - m_nOverRegio, BmpIn.Height);
  DrawVerticalTransition(BmpOut.Canvas.Handle, BmpIn.Canvas.Handle, rcTemp);
  BmpIn.Assign(BmpOut);
  BmpOut.Free;
end;

end.

