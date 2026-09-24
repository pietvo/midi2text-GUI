unit TextBox;

{$mode ObjFPC}{$H+}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
            SynEdit, SynEditKeyCmds, LCLType, ActnList, StdActns;

type

      { TForm2 }

      TForm2 = class(TForm)
           actEditRedo: TAction;
           actFileSave: TAction;
           actFileOpen: TAction;
           actFileSaveAs: TAction;
           actEditCopy: TEditCopy;
           actEditCut: TEditCut;
           actEditPaste: TEditPaste;
           actEditSelectAll: TEditSelectAll;
           actEditUndo: TEditUndo;
           actSearchFind: TSearchFind;
           actSearchReplace: TSearchReplace;
           ActionList1: TActionList;
           Button2Open: TButton;
           Button2Save: TButton;
           Button2SaveAs: TButton;
           MemoLabel: TLabel;
           PopupMenu1: TPopupMenu;
           MenuUndo1: TMenuItem;
           MenuRedo1: TMenuItem;
           MenuCopy1: TMenuItem;
           MenuCut1: TMenuItem;
           MenuPaste1: TMenuItem;
           MenOpen1: TMenuItem;
           MenuSaveAs1: TMenuItem;
           MenuSave1: TMenuItem;
           MenuSelectAll1: TMenuItem;
           MenuSelectAll2: TMenuItem;
           MainMenu2: TMainMenu;
           Menu2File: TMenuItem;
           Menu2Edit: TMenuItem;
           Menu2Open: TMenuItem;
           Menu2Save: TMenuItem;
           Menu2SaveAs: TMenuItem;
           Menu2Copy: TMenuItem;
           Menu2Cut: TMenuItem;
           Menu2Paste: TMenuItem;
           Separator2: TMenuItem;
           MenuRedo2: TMenuItem;
           Menu2Undo: TMenuItem;
           OpenDialog1: TOpenDialog;
           SaveDialog1: TSaveDialog;
           Separator1: TMenuItem;
           Separator3: TMenuItem;
           Separator4: TMenuItem;
           Separator5: TMenuItem;
           SynEdit1: TSynEdit;
           procedure actActions1Update(Sender: TObject);
           procedure actEditCutExecute(Sender: TObject);
           procedure actEditPasteExecute(Sender: TObject);
           procedure actEditRedoExecute(Sender: TObject);
           procedure actEditSelectAllExecute(Sender: TObject);
           procedure actEditUndoExecute(Sender: TObject);
           procedure actEditCopyExecute(Sender: TObject);
           procedure FormCreate(Sender: TObject);
           procedure SynEdit1Change(Sender: TObject);
           procedure TextBoxOpen(Sender: TObject);
           procedure TextBoxSave(Sender: TObject);
           procedure TextBoxSaveAs(Sender: TObject);
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
  SynEdit1.ScrollBars := ssBoth;
  SynEdit1.Lines.LoadFromStream(stream);
  // We have to manipulate the ScrollBars this way to prevent a problem
  SynEdit1.ScrollBars := ssAutoBoth;
  SynEdit1.Invalidate; // Force UI synchronization

  ClearFileName;
  if Assigned(SynEdit1.OnChange) then
    SynEdit1.OnChange(SynEdit1);
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


procedure TForm2.SynEdit1Change(Sender: TObject);
var
  i:integer;
  line: string;
  validMidi: Boolean;
begin
  validMidi := False;
  for i:=0 to Form2.SynEdit1.Lines.Count-1 do
      begin
         line := Trim(Form2.SynEdit1.Lines[i]);
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
      SynEdit1.Top := MemoTop;
        end
    else
    begin
      if MemoLabel.Caption = '' then
      MemoLabel.Caption := '⚠️  Please enter valid MFile line';
      MemoLabel.Visible := True;
      MemoLabel.Height := 20;
      MemoLabel.Top := MemoTop;
      SynEdit1.Top := MemoTop + MemoLabel.Height;
      // MemoLabel.BringToFront();
        end;
end;


procedure TForm2.FormCreate(Sender: TObject);
{$IFDEF DARWIN}
var
  i: Integer;
  procedure AddKey(const ACmd: TSynEditorCommand; const AKey: word; const AShift: TShiftState);
  begin
    SynEdit1.AddKey(ACmd, AKey, AShift, VK_UNKNOWN, []);
  end;
{$ENDIF}
begin
  SynEdit1.Highlighter := nil;

  // Define the OnChange handler of SynEdit1
  SynEdit1.OnChange := @SynEdit1Change;
  ClearFileName;

  // Redefine Keys for MacOS

  {$IFDEF DARWIN}
    // Macos Specific Keyboard Mapping for text editing
    with SynEdit1.Keystrokes do
    begin
      // Count backwards because we have a Delete
      for i := Count - 1 downto 0 do
        with Items[i] do
        begin
          // Remove undesired Ctrl+arrow shortcuts
          // these could conflict with MacOS keys
          // Remove Ctrl-N because we need it below
         if ((Key in [VK_N, VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN]) and (ssCtrl in Shift))
         // Remove column select mode
            or (Command in [ecNormalSelect, ecColumnSelect, ecLineSelect]) then
            Delete(i);
        end;
      // Add native macOS Cmd (ssMeta) and Option (ssAlt) keystrokes
      // Cmd + Arrow (Navigation to begin/end of line or document)
      AddKey(ecLineStart, VK_LEFT, [ssMeta]); // Cmd + Left
      AddKey(ecLineStart, VK_A, [ssCtrl]); // Ctrl-A
      AddKey(ecLineEnd, VK_RIGHT, [ssMeta]); // Cmd + Right
      AddKey(ecLineEnd, VK_E, [ssCtrl]); // Ctrl-E
      AddKey(ecEditorTop, VK_UP, [ssMeta]); // Cmd + Up
      AddKey(ecEditorBottom, VK_DOWN, [ssMeta]); // Cmd + Down
      // Cmd + Shift + Arrows (Select to begin/end)
      AddKey(ecSelLineStart, VK_LEFT, [ssMeta, ssShift]);
      AddKey(ecSelLineEnd, VK_RIGHT, [ssMeta, ssShift]);
      AddKey(ecSelEditorTop, VK_UP, [ssMeta, ssShift]);
      AddKey(ecSelEditorBottom, VK_DOWN, [ssMeta, ssShift]);
      // Option (Alt) + Arrows (jump words)
      AddKey(ecWordLeft, VK_LEFT, [ssAlt]); // Option + Left
      AddKey(ecWordRight, VK_RIGHT, [ssAlt]); // Option + Right
      // Option (Alt) + Shift + Arrows (word select)
      AddKey(ecSelWordLeft, VK_LEFT, [ssAlt, ssShift]);
      AddKey(ecSelWordRight, VK_RIGHT, [ssAlt, ssShift]);
      // misc
      AddKey(ecDeleteChar, VK_D, [ssCtrl]);  // Ctrl-D
      AddKey(ecLeft, VK_B, [ssCtrl]);        // Ctrl-B
      AddKey(ecRight, VK_F, [ssCtrl]);       // Ctrl-F
      AddKey(ecUp, VK_P, [ssCtrl]);          // Ctrl-P
      AddKey(ecDown, VK_N, [ssCtrl]);        // Ctrl-N
      AddKey(ecInsertLine, VK_O, [ssCtrl]);  // Ctrl-O
    end;
  {$ENDIF}

  // Set Action shortcuts - ssModifier is Meta on MacOS, Ctrl on Windows/Linux
  actEditUndo.ShortCut := ShortCut(VK_Z, [ssModifier]);
  actEditRedo.ShortCut := ShortCut(VK_Z, [ssModifier, ssShift]);
  actEditCut.ShortCut := ShortCut(VK_X, [ssModifier]);
  actEditCopy.ShortCut := ShortCut(VK_C, [ssModifier]);
  actEditPaste.ShortCut := ShortCut(VK_V, [ssModifier]);
  actEditSelectAll.ShortCut := ShortCut(VK_A, [ssModifier]);
  actSearchFind.ShortCut := ShortCut(VK_F, [ssModifier]);
  //actSearchReplace.ShortCut := ShortCut(VK_F, [ssModifier]);
  actFileOpen.ShortCut := ShortCut(VK_O, [ssModifier]);
  actFileSave.ShortCut := ShortCut(VK_S, [ssModifier]);
  actFileSaveAs.ShortCut := ShortCut(VK_S, [ssModifier, ssShift]);
end;


procedure TForm2.actEditCutExecute(Sender: TObject);
begin
  SynEdit1.CommandProcessor(ecCut, '', nil);
end;


procedure TForm2.actActions1Update(Sender: TObject);
begin
  actEditUndo.Enabled := SynEdit1.CanUndo;
  actEditRedo.Enabled := SynEdit1.CanRedo;
  actEditCut.Enabled := SynEdit1.SelText <> '';
  actEditCopy.Enabled := SynEdit1.SelText <> '';
  actEditPaste.Enabled := SynEdit1.CanPaste;
  actEditSelectAll.Enabled := SynEdit1.Text <> '';
  //actFileOpen.Enabled := True;
  actFileSave.Enabled := (Form2.savedFileName <> '') and (validMidiText);
  actFileSaveAs.Enabled := validMidiText;
end;


procedure TForm2.actEditPasteExecute(Sender: TObject);
begin
  SynEdit1.CommandProcessor(ecPaste, '', nil);
end;


procedure TForm2.actEditRedoExecute(Sender: TObject);
begin
  SynEdit1.Redo;
end;


procedure TForm2.actEditSelectAllExecute(Sender: TObject);
begin
  SynEdit1.CommandProcessor(ecSelectAll, '', nil);
end;


procedure TForm2.actEditUndoExecute(Sender: TObject);
begin
  SynEdit1.Undo;
end;


procedure TForm2.actEditCopyExecute(Sender: TObject);
begin
  SynEdit1.CommandProcessor(ecCopy, '', nil);
end;


procedure TForm2.TextBoxOpen(Sender: TObject);
var filename: string;
begin
  OpenDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    SetFileName(OpenDialog1.Filename);
    // We have to manipulate the ScrollBars this way to prevent a problem
    SynEdit1.ScrollBars := ssBoth;
    SynEdit1.Lines.LoadFromFile(savedFileName);
    SynEdit1.ScrollBars := ssAutoBoth;
    SynEdit1.Invalidate; // Force UI synchronization

    { primitive check if it is a midi text }
    if Assigned(SynEdit1.OnChange) then
      SynEdit1.OnChange(SynEdit1);
  end
end;


procedure TForm2.TextBoxSave(Sender: TObject);
begin
  if savedFileName <> '' then
    SynEdit1.Lines.SaveToFile(savedFileName);
end;


procedure TForm2.TextBoxSaveAs(Sender: TObject);
begin
  SaveDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if SaveDialog1.Execute then
  begin
    SetFileName(SaveDialog1.Filename);
    TextBoxSave(Sender);
    end;
end;

end.
