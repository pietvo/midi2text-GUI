unit TextBox;

{$mode ObjFPC}{$H+}

interface

uses
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
            SynEdit, SynEditKeyCmds, SynEditTypes, LCLType, ActnList, StdActns,
            ExtCtrls;

type
    SRType = (srFind, srReplace, srReplaceAll);

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
           actFindNext: TAction;
           actFindPrev: TAction;
           actReplaceAll: TAction;
           actReplace: TAction;
           actSearchFind: TAction;
           ActionList1: TActionList;
           ButtonCloseFind: TButton;
           ButtonPrev: TButton;
           Button2Open: TButton;
           Button2Save: TButton;
           Button2SaveAs: TButton;
           ButtonNext: TButton;
           ButtonReplAll: TButton;
           ButtonRepl: TButton;
           CheckBoxTOP: TCheckBox;
           CheckBoxWW: TCheckBox;
           CheckBoxMC: TCheckBox;
           CheckBoxRE: TCheckBox;
           EditFind: TEdit;
           EditRepl: TEdit;
		   LabelModified: TLabel;
           LabelFind: TLabel;
           LabelRepl: TLabel;
           MemoLabel: TLabel;
           Menu2Find: TMenuItem;
           MenuFind1: TMenuItem;
           PanelFind: TPanel;
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
           procedure actEditRedoExecute(Sender: TObject);
           procedure actFindNextExecute(Sender: TObject);
           procedure actFindPrevExecute(Sender: TObject);
           procedure actReplaceAllExecute(Sender: TObject);
           procedure actReplaceExecute(Sender: TObject);
           procedure actSearchFindExecute(Sender: TObject);
           procedure ButtonCloseFindClick(Sender: TObject);
		   procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
           procedure FormCreate(Sender: TObject);
           procedure SynEdit1Change(Sender: TObject);
           procedure TextBoxOpen(Sender: TObject);
           procedure TextBoxSave(Sender: TObject);
           procedure TextBoxSaveAs(Sender: TObject);
           procedure ClearFileName;
           procedure SetFileName(fn: string);
           procedure SetMemoLabel;
           procedure HideMemoLabel;
           procedure DoSearch(forward: TSynSearchOptions; replace: SRType);

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
    FindActive: Boolean = False;
    FirstSearch: Boolean;
    SearchDirection: TSynSearchOptions;
    SearchFound: Boolean;

implementation

Uses MainForm;

{$R *.lfm}

{
  This method can be used to load the text of the TextBox from an
  external TStream, for example the standard output of an external command.
}

procedure TForm2.setText(stream: TStream);
begin
  SynEdit1.ScrollBars := ssBoth;
  SynEdit1.Lines.LoadFromStream(stream);
  // We have to manipulate the ScrollBars this way to prevent a problem
  SynEdit1.ScrollBars := ssAutoBoth;
  SynEdit1.Invalidate; // Force UI synchronization
  SynEdit1.Modified := True;
  SynEdit1Change(SynEdit1);
  ClearFileName;
  if Assigned(SynEdit1.OnChange) then
    SynEdit1.OnChange(SynEdit1);
end;


procedure TForm2.ClearFileName;
begin
  savedFileName := '';
  actFileSave.Enabled := False;
end;


procedure TForm2.SetFileName(fn: string);
begin
  savedFileName := fn;
  actFileSave.Enabled := True;
end;


procedure TForm2.HideMemoLabel;
begin
  MemoLabel.Caption := '';
  MemoLabel.Visible := False;
  MemoLabel.Height := 0;
end;


procedure TForm2.SetMemoLabel;
begin
  if FindActive then Exit;
  if Form2.validMidiText then
  begin
    HideMemoLabel;
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


procedure TForm2.SynEdit1Change(Sender: TObject);
const
  CheckMark ='✔';
  ModMark = '*';
var
  i:integer;
  line: string;
  validMidi: Boolean;
begin
  validMidi := False;
  for i:=0 to Form2.SynEdit1.Lines.Count-1 do
    begin
       line := Trim(Form2.SynEdit1.Lines[i]);
         // Skip blank lines and comment;
         // check first non-blank, non-comment line
         if (line <> '') and (line[1] <> '#') then
         begin
           validMidi := copy(line, 1, 6) = 'MFile ';
           Break;
         end
    end;
  Form2.validMidiText := validMidi;
  if validMidi and Assigned(CallBackProc) then
    CallBackProc;
  SetMemoLabel;
  
  if SynEdit1.Modified then
  begin
    LabelModified.Font.Color := clRed;
    LabelModified.Font.Size := 24;
        LabelModified.Caption := ModMark;
  end
  else
  begin
    LabelModified.Font.Color := clGreen;
    LabelModified.Font.Size := 14;
    LabelModified.Caption := CheckMark;
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
  actFindNext.ShortCut := ShortCut(VK_G, [ssModifier]);
  actFindPrev.ShortCut := ShortCut(VK_G, [ssModifier, ssShift]);
  actFileOpen.ShortCut := ShortCut(VK_O, [ssModifier]);
  actFileSave.ShortCut := ShortCut(VK_S, [ssModifier]);
  actFileSaveAs.ShortCut := ShortCut(VK_S, [ssModifier, ssShift]);
end;


procedure TForm2.actActions1Update(Sender: TObject);
begin
  actEditUndo.Enabled := SynEdit1.CanUndo;
  actEditRedo.Enabled := SynEdit1.CanRedo;
  actEditCut.Enabled := SynEdit1.SelText <> '';
  actEditCopy.Enabled := SynEdit1.SelText <> '';
  actEditPaste.Enabled := SynEdit1.CanPaste;
  actEditSelectAll.Enabled := SynEdit1.Text <> '';
  actFileSave.Enabled := (Form2.savedFileName <> '') and (validMidiText);
  actFileSaveAs.Enabled := validMidiText;
end;


procedure TForm2.actEditRedoExecute(Sender: TObject);
begin
  SynEdit1.Redo;
end;


procedure TForm2.DoSearch(forward: TSynSearchOptions; replace: SRType);
//srFind, srReplace, srReplaceAll
var
  options: TSynSearchOptions;
  nrFound: integer;
  endMessage: string;
  lastLine: integer;
  extPosition: TPoint;

begin
  SearchDirection := forward; // remember Search direction
  options := SearchDirection;
  if CheckBoxWW.Checked then
    options := options + [ssoWholeWord];
  if CheckBoxMC.Checked then
    options := options + [ssoMatchCase];
  if CheckBoxRE.Checked then
    options := options + [ssoRegExpr];
  if CheckBoxTOP.Checked then
  begin
    options := options + [ssoEntireScope];
    CheckBoxTOP.Checked := False;
    end;
    if not FirstSearch then
  begin
    if (replace = srReplace) and SearchFound then
    begin
      //SynEdit1.SelText := EditRepl.Text // doesn't work for regexp
      SynEdit1.SearchReplace(EditFind.Text, EditRepl.Text,
                             options + [ssoSelectedOnly, ssoReplace]);
    end;
    options := options + [ssoFindContinue];
    end;

  if (replace = srReplaceAll) then
  begin
    if SearchFound then     // Replace the just found instance
      SynEdit1.SearchReplace(EditFind.Text, EditRepl.Text,
                             options + [ssoSelectedOnly, ssoReplace]);
    // replace the rest
    nrFound := SynEdit1.SearchReplace(EditFind.Text, EditRepl.Text,
                                      options + [ssoReplaceAll])
    end
    else
  begin
    nrFound := SynEdit1.SearchReplace(EditFind.Text, '', options);
    FirstSearch := False;
  end;

    if nrFound = 0 then  // At end of search
  begin
    // Ask user to continue at top/bottom
    if SearchDirection = [] then // Forward
    begin
      endMessage := 'End of document. Contine at top?';
      extPosition := Point(1,1);
    end
    else
    begin
      endMessage := 'Begin of document. Contine at bottom?';
      lastline := SynEdit1.Lines.Count;
      if lastline > 0 then
        extPosition := Point(Length(SynEdit1.Lines[lastline - 1]) + 1, lastline)
      else
        extPosition := Point(1,1); // empty document
    end;
    if MessageDlg(endMessage, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      // start at row 1, column 1
      SynEdit1.CaretXY := extPosition;
      options := options + [ssoFindContinue];
      nrFound := SynEdit1.SearchReplace(EditFind.Text, '', options);
        end;
    end;

  SearchFound := (nrFound > 0);
end;


procedure TForm2.actFindNextExecute(Sender: TObject);
begin
  DoSearch([], srFind);
end;


procedure TForm2.actFindPrevExecute(Sender: TObject);
begin
  DoSearch([ssoBackwards], srFind);
end;


{ Start a Find/Replace dialog (panel) }

procedure TForm2.actSearchFindExecute(Sender: TObject);
begin
  HideMemoLabel;
  SynEdit1.Top := MemoTop + PanelFind.Height;
  PanelFind.Visible := True;
  EditFind.SetFocus;
  FindActive := True;
  FirstSearch := True;
  SearchFound := False;
end;


procedure TForm2.actReplaceExecute(Sender: TObject);
begin
  DoSearch(SearchDirection, srReplace);
end;


procedure TForm2.actReplaceAllExecute(Sender: TObject);
begin
  DoSearch(SearchDirection, srReplaceAll);
end;


procedure TForm2.ButtonCloseFindClick(Sender: TObject);
begin
  PanelFind.Visible := False;
  FindActive := False;
  SetMemoLabel;
end;


procedure TForm2.TextBoxOpen(Sender: TObject);
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
    SynEdit1.Modified := False;
    SynEdit1Change(Sender);

    { primitive check if it is a midi text }
    if Assigned(SynEdit1.OnChange) then
      SynEdit1.OnChange(SynEdit1);
    SetMemoLabel;
  end
end;


procedure TForm2.TextBoxSave(Sender: TObject);
begin
  if savedFileName <> '' then
  begin
    SynEdit1.Lines.SaveToFile(savedFileName);
    SynEdit1.Modified := False;
    SynEdit1Change(Sender);
	end;
end;


procedure TForm2.TextBoxSaveAs(Sender: TObject);
begin
  if savedFileName <> '' then
    SaveDialog1.FileName := savedFileName;
  SaveDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if SaveDialog1.Execute then
  begin
    SetFileName(SaveDialog1.Filename);
    TextBoxSave(Sender);
    end;
end;


// This is in fact called when Form1 will be closed

procedure TForm2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  Response: Integer;
begin
  if SynEdit1.Modified then
  begin
    Response := MessageDlg('Unsaved Changes',
                           'The text has been modified. Do you want to save?',
                           mtConfirmation, [mbYes, mbNo, mbCancel], 0);

    if Response = mrYes then
    begin
      // Start the Save As dialog
      Form2.TextBoxSaveAs(Sender);
      // If successful, allow close
      CanClose := not SynEdit1.Modified;
    end
    else if Response = mrNo then
    begin
      CanClose := True; // Discard changes and close
    end
    else
    begin
      CanClose := False; // Cancel closing the app
    end;
  end
  else
  begin
    CanClose := True; // No modifications, safe to close
  end;
end;

end.
