////////////////////////////////////////////////////////////////////////////////
//
//  Workshop Object Pascal EATI 2018
//  Zombie Minesweeper
//
//   Todos:
//   - GamveOver com final feliz
//   - Adicionar diferentes níveis de dificuldade (aumentando ou diminuindo o
//    tamanho do grid e dos zumbis)
//
////////////////////////////////////////////////////////////////////////////////

unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls, Graphics, Dialogs,
  Grids, ExtCtrls, StdCtrls, Buttons, Types;

////////////////////////////////////////////////////////////////////////////////
//
// Criação do tipo de dados que representa cada célula do grid
//
////////////////////////////////////////////////////////////////////////////////
type
  { TMinesweeper }
  TMineCell = record
    bRevealed   : Boolean;
    nNeighbors  : Integer;
    bIsZombie     : Boolean;
    bIsFlag     : Boolean;
  end;

  TMinesweeper = class(TForm)
    btSmile: TSpeedButton;
    GridMines: TStringGrid;
    procedure btSmileClick(Sender: TObject);
    procedure GridMinesClick(Sender: TObject);
    procedure GridMinesDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure GridMinesMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    m_nCols       : Integer;
    m_nRows       : Integer;
    m_arMineCells : array of array of TMineCell;

    m_nMines      : Integer;
    m_nUsedFlags  : Integer;
    m_bGameOver   : Boolean;

    procedure ResetGrid;
    procedure PlaceMines;
    procedure SetGridNeighbors;
    procedure RevealCell(Col, Row : Integer);
    procedure FloodFill(Col, Row : Integer);
    function  CountNeighbors(Col, Row : Integer) : Integer;
    procedure GameOver;

  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Minesweeper: TMinesweeper;

implementation

const
  c_cellWidth = 30;

{$R *.lfm}

{ TMinesweeper }

////////////////////////////////////////////////////////////////////////////////
//
// Construtor do Form do campo minado, em que são realizadas todas as
// inicializações necessárias
//
////////////////////////////////////////////////////////////////////////////////
constructor TMinesweeper.Create(AOwner: TComponent);
var
  nIndex : Integer;
begin
  inherited;

  // Numero padrão de Colunas e linhas
  m_nCols  := 10;
  m_nRows  := 10;

  m_nMines     := 10;
  m_nUsedFlags := 0;

  // define tamanho de array de celulas
  SetLength(m_arMineCells, m_nCols, m_nRows);

  // define tamanho do form
  Self.Width  := m_nCols*c_cellWidth + 50;
  Self.Height := m_nRows*c_cellWidth + 80;

  // define o numero de Colunas e linhs do grid
  GridMines.ColCount:= m_nCols;
  GridMines.RowCount:= m_nRows;

  // define altura e largura do grid
  GridMines.Width := m_nCols*c_cellWidth+Round(m_nCols/2);
  GridMines.Height:= m_nRows*c_cellWidth+Round(m_nRows/2);

  // define posicao do botao smile
  btSmile.Left:= Trunc(GridMines.Width/2);

  // define altura e largura das celulas
  for nIndex := 0 to m_nRows-1 do
    begin
      GridMines.ColWidths[nIndex] := c_cellWidth;
      GridMines.RowHeights[nIndex] := c_cellWidth;
    end;

  m_bGameOver := False;

  ResetGrid;
  PlaceMines;
  SetGridNeighbors;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Seta o número de zumbis vizinhos de todas as células do grid
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.SetGridNeighbors;
var
  i, j   : Integer;
begin
  for i := 0 to m_nCols-1 do
    for j := 0 to m_nRows-1 do
      begin
        m_arMineCells[i][j].nNeighbors:= CountNeighbors(i, j);
       // GridMines.Cells[i, j] := IntToStr(m_arMineCells[i, j].nNeighbors);
      end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Conta o número de zumbis vizinhos de determinado zumbi
//
////////////////////////////////////////////////////////////////////////////////
function TMinesweeper.CountNeighbors(Col, Row: Integer) : Integer;
var
  nTotal : Integer;
  i, j : Integer;
begin
  nTotal := 0;

  if (m_arMineCells[Col][Row].bIsZombie) then
    nTotal := -1
  else
    begin
      for i := Col-1 to Col+1 do
        for j := Row-1 to Row+1 do
          begin
            if (i>=0) and (j>=0) and (i<m_nCols) and (j<m_nRows) then
              begin
                if m_arMineCells[i][j].bIsZombie then
                  Inc(nTotal);
              end;
          end;
    end;
  Result := nTotal;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Posiciona as bombas (zumbis)
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.PlaceMines;
var
  i, j   : Integer;
  nIndex : Integer;
begin
  Randomize;
  for nIndex := 0 to m_nMines-1 do
    begin
      i := Random(m_nCols);
      j := Random(m_nRows);

      m_arMineCells[i][j].bIsZombie  := True;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Reseta o grid para o estado inicial em que nenhuma célula está revelada
// e nenhum zumbi está posicionado
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.ResetGrid;
var
  i, j : Integer;
begin
  for i := 0 to m_nCols-1 do
    for j := 0 to m_nRows-1 do
      begin
        m_arMineCells[i][j].bIsZombie  := False;
        m_arMineCells[i][j].bRevealed:= False;
        m_arMineCells[i][j].bIsFlag  := False;
        m_arMineCells[i][j].nNeighbors:= 0;

        GridMines.Cells[i, j] := '';
      end;

  m_nUsedFlags := 0;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Evento de click do botão Smile
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.btSmileClick(Sender: TObject);
const
  c_addrImgSmile = 'img/smileIcon.bmp';
var
  Bitmap : TBitMap;
begin
  if m_bGameOver then
    begin
      m_bGameOver := False;
      if fileexists(c_addrImgSmile) then
       begin
         Bitmap := TBitmap.Create;
         Bitmap.LoadFromFile(c_addrImgSmile);
         btSmile.Glyph := Bitmap;
         Bitmap.Free;
       end;
    end;

  ResetGrid;
  PlaceMines;
  SetGridNeighbors;

  // repinta o grid
  GridMines.Invalidate;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Evento de click nas células do grid
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.GridMinesClick(Sender: TObject);
begin
  RevealCell(GridMines.Col, GridMines.Row);
end;

////////////////////////////////////////////////////////////////////////////////
//
// Método que revela a célula clicada
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.RevealCell(Col, Row : Integer);
begin
  if not m_bGameOver and not m_arMineCells[Col][Row].bIsFlag then
    begin
      m_arMineCells[Col, Row].bRevealed := True;

      if m_arMineCells[Col, Row].bIsZombie  then
        begin
          GameOver;
        end
      else if (m_arMineCells[Col, Row].nNeighbors = 0) then
        begin
          FloodFill(Col, Row);
        end;
    end;

  GridMines.Invalidate;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Verifica se os vizinhos da célula clicada tem zero vizinhos zumbis
// e vai revelando automaticamente essas células
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.FloodFill(Col, Row : Integer);
var
  i, j : Integer;
begin
  for i := Col-1 to Col+1 do
    for j := Row-1 to Row+1 do
      begin
        if (i >= 0) and (j >= 0) and (i < m_nCols) and (j < m_nRows) then
          begin
            if not (m_arMineCells[i][j].bIsZombie) and not (m_arMineCells[i][j].bRevealed) then
              begin
                RevealCell(i, j);
              end;
          end;
      end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Evento de pintura das celulas do grid
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.GridMinesDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
const
  c_addrImgHead = 'img/head.bmp';
  c_addImgHand  = 'img/hand.bmp';
  c_addrImgOver = 'img/lostIcon.bmp';
  c_addrImgFlag = 'img/cross.bmp';
var
  Bitmap   : TBitmap;
  vTxtSt   : TTextStyle;
begin
  Bitmap := TBitmap.Create;

  if m_arMineCells[aCol][aRow].bIsFlag and fileexists(c_addrImgHead) then
    begin
     Bitmap.LoadFromFile(c_addrImgFlag);
     GridMines.Canvas.StretchDraw(aRect,bitmap);
    end
  else if m_arMineCells[aCol, aRow].bRevealed then
    begin
      if m_arMineCells[aCol, aRow].bIsZombie and fileexists(c_addrImgHead) then
       begin
         Bitmap.LoadFromFile(c_addrImgHead);
         GridMines.Canvas.StretchDraw(aRect,bitmap);

         if fileexists(c_addrImgOver) then
           begin
             Bitmap.LoadFromFile(c_addrImgOver);
             btSmile.Glyph := Bitmap;
           end;
       end
      else if (m_arMineCells[aCol, aRow].nNeighbors = 0) and fileexists(c_addImgHand) then
       begin
         Bitmap.LoadFromFile(c_addImgHand);
         GridMines.Canvas.StretchDraw(aRect,bitmap);
       end
      else
        begin
          with GridMines do
            begin
              vTxtSt := Canvas.TextStyle;
              vTxtSt.Alignment := taCenter;
              vTxtSt.Layout    := tlCenter;
              Canvas.TextStyle := vTxtSt;
              Canvas.Brush.Color:= clWhite;
              Canvas.FillRect(aRect);
              Canvas.TextRect(aRect, aRect.Left, aRect.Top, IntToStr(m_arMineCells[aCol, aRow].nNeighbors));
            end;
        end;
    end;

  Bitmap.Free;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Evento de MouseUp para posicionar as bandeirinhas quando a célula é clicada
// com o botão direito
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.GridMinesMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row : Integer;
begin
   if (Button = mbRight) and (not m_bGameOver) then
     begin
      GridMines.MouseToCell( X,Y, Col, Row );

      if m_arMineCells[Col][Row].bIsFlag then
        begin
          m_nUsedFlags := m_nUsedFlags - 1;
          m_arMineCells[Col][Row].bIsFlag := False;
        end
      else if m_nUsedFlags < m_nMines then
        begin
          Inc(m_nUsedFlags);
          m_arMineCells[Col][Row].bIsFlag := True;
        end;

      GridMines.Invalidate;
     end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// Função de GameOver. Esse função é chamada quando uma célula zumbi é clicada.
// Ela revela onde estão todos os outros zumbis.
//
////////////////////////////////////////////////////////////////////////////////
procedure TMinesweeper.GameOver;
var
  i, j : Integer;
begin
  m_bGameOver := True;

  for i := 0 to m_nCols-1 do
    for j := 0 to m_nRows-1 do
      begin
        if  m_arMineCells[i][j].bIsZombie and not( m_arMineCells[i][j].bRevealed) then
          m_arMineCells[i][j].bRevealed := True;
      end;
end;

end.

