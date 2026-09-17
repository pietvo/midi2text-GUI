unit TextBox;

{$mode ObjFPC}{$H+}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus;

type

			{ TForm2 }

      TForm2 = class(TForm)
						Button2Open: TButton;
						Button2Save: TButton;
						Button2SaveAs: TButton;
						MainMenu2: TMainMenu;
						MemoLabel: TLabel;
						Memo1: TMemo;
						Menu2File: TMenuItem;
						Menu2Edit: TMenuItem;
						Menu2Open: TMenuItem;
						Menu2Save: TMenuItem;
						Menu2SaveAs: TMenuItem;
						Menu2Copy: TMenuItem;
						Menu2Cut: TMenuItem;
						Menu2Paste: TMenuItem;
						OpenDialog1: TOpenDialog;
						SaveDialog1: TSaveDialog;
            procedure OpenClick(Sender: TObject);
            procedure FormCreate(Sender: TObject);
            procedure Memo1Change(Sender: TObject);
						procedure SaveAsClick(Sender: TObject);
						procedure SaveClick(Sender: TObject);
            procedure ClearFileName;
            procedure SetFileName(fn: string);

      private
           savedFileName: string;

      public
           validMidiText: Boolean;
           CallBackProc: procedure;
           procedure setText(stream: TStream);


      end;

const
    MemoTop = 40; // default position of Memo in Form2
var
      Form2: TForm2;

implementation

Uses MainForm;

{$R *.lfm}

procedure TForm2.setText(stream: TStream);
begin
  Memo1.Lines.LoadFromStream(stream);
  ClearFileName;
  if Assigned(Memo1.OnChange) then
    Memo1.OnChange(Memo1);
end;


procedure TForm2.ClearFileName;
begin
  savedFileName := '';
  Button2Save.Enabled := False;
  Menu2Save.Enabled := False;
end;


procedure TForm2.SetFileName(fn: string);
begin
  savedFileName := fn;
  Button2Save.Enabled := True;
  Menu2Save.Enabled := True;
end;


procedure TForm2.Memo1Change(Sender: TObject);
var
  i:integer;
  line: string;
  validMidi: Boolean;
begin
  validMidi := False;
  for i:=0 to Form2.Memo1.Lines.Count-1 do
	  begin
		 line := Trim(Form2.Memo1.Lines[i]);
		   // Skip blank lines; check first non-blank line
		   if line <> '' then
		   begin
		     validMidi := copy(line, 1, 6) = 'MFile ';
		     Break;
		   end
		end;
    Form2.validMidiText := validMidi;
    if validMidi then
    begin
      if Assigned(CallBackProc) then
        CallBackProc;
      MemoLabel.Caption := '';
      MemoLabel.Visible := False;
      MemoLabel.Height := 0;
      Memo1.Top := MemoTop;
		end
    else
    begin
      if MemoLabel.Caption = '' then
      MemoLabel.Caption := '⚠️  Please enter valid MFile line';
      MemoLabel.Visible := True;
      MemoLabel.Height := 20;
      MemoLabel.Top := MemoTop;
      Memo1.Top := MemoTop + MemoLabel.Height;
      // MemoLabel.BringToFront();
		end;
end;


procedure TForm2.FormCreate(Sender: TObject);
begin
  // Koppel de procedure aan het OnChange event van Memo1
  Memo1.OnChange := @Memo1Change;
  ClearFileName;
end;


procedure TForm2.OpenClick(Sender: TObject);
var filename: string;
begin
  OpenDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    SetFileName(OpenDialog1.Filename);
    Memo1.Lines.LoadFromFile(savedFileName);
    { primitive check if it is a midi text }
    if Assigned(Memo1.OnChange) then
      Memo1.OnChange(Memo1);
  end
end;


procedure TForm2.SaveClick(Sender: TObject);
begin
  if savedFileName <> '' then
    Memo1.Lines.SaveToFile(savedFileName);
end;


procedure TForm2.SaveAsClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    SetFileName(SaveDialog1.Filename);
  	SaveClick(Sender);
	end;
end;


end.
