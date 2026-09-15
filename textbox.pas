unit TextBox;

{$mode ObjFPC}{$H+}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus;

type

			{ TForm2 }

      TForm2 = class(TForm)
						button_open: TButton;
						button_save: TButton;
						button_save_as: TButton;
						MemoLabel: TLabel;
						Memo1: TMemo;
            procedure FormCreate(Sender: TObject);
            procedure Memo1Change(Sender: TObject);

      private
					//

      public
           validMidiText: Boolean;
           CallBackProc: procedure;
           procedure setText(content: string);
      end;

const
    MemoTop = 40; // default position of Memo in Form2
var
      Form2: TForm2;

implementation

Uses MainForm;

{$R *.lfm}

procedure TForm2.setText(content: string);
begin
  Memo1.Text := content;
  if Assigned(Memo1.OnChange) then
    Memo1.OnChange(Memo1);
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
end;


end.
