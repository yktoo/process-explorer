program ProcessExplorer;

uses
  Forms,
  Main in 'Main.pas' {fMain},
  ConsVarsTypes in 'ConsVarsTypes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'ProcessExplorer';
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
