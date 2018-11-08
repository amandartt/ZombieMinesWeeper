program CampoMinado;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, runtimetypeinfocontrols, Main
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='Zombi Minesweeper';
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TMinesweeper, Minesweeper);
  Application.Run;
end.

