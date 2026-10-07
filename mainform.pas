unit MainForm;

{$mode objfpc}{$H+}

interface

uses
      {$IFDEF UNIX}
       BaseUnix, // Required for fpClose
      {$ENDIF}
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
            HelpPanel, TextBox, Process, LCLType, Menus, ComCtrls, Math;

type

            { TForm1 }

      TForm1 = class(TForm)
            ButtonConvert2: TButton;
            ButtonMidiIn: TButton;
            ButtonTextInOut: TButton;
            ButtonTextBoxOut: TButton;
            ButtonConvert1: TButton;
            ButtonTextIn: TButton;
            ButtonMidiOut: TButton;
            ButtonTextBoxIn: TButton;
            ButtonTextOut: TButton;
            CheckBoxOptionM: TCheckBox;
            CheckBoxOptionN: TCheckBox;
            CheckBoxOptionOff1: TCheckBox;
            CheckBoxOptionOff2: TCheckBox;
            CheckBoxOptionOn1: TCheckBox;
            CheckBoxOptionOn2: TCheckBox;
            CheckBoxOptionB: TCheckBox;
            CheckBoxOptionV: TCheckBox;
            CheckBoxOptionF: TCheckBox;
            CheckBoxOptionR: TCheckBox;
            Edit1: TEdit;
            FPosWarningBox: TLabel;
            Image1: TImage;
            Image2: TImage;
            Label1: TLabel;
            Label10: TLabel;
            Label11: TLabel;
            Label12: TLabel;
            Label16: TLabel;
            Label18: TLabel;
            Label19: TLabel;
            LabelTextIn: TLabel;
            LabelOptions: TLabel;
            Label13: TLabel;
            Label14: TLabel;
            Label15: TLabel;
            LabelMidiIn: TLabel;
            Label17: TLabel;
            Label2: TLabel;
            Label22: TLabel;
            Label3: TLabel;
            Label4: TLabel;
            Label5: TLabel;
            Label6: TLabel;
            Label7: TLabel;
            Label8: TLabel;
            Label9: TLabel;
            LabelTextOut: TLabel;
            LabelMidiOut: TLabel;
            MainMenu1: TMainMenu;
            MenuFile: TMenuItem;
            MenuItemHelp: TMenuItem;
            MenuItemQuit: TMenuItem;
            MenuShowTextBox: TMenuItem;
            MenuHideTextBox: TMenuItem;
            Separator2: TMenuItem;
            Separator1: TMenuItem;
            MenuItemTextBox: TMenuItem;
            MenuItemOpen: TMenuItem;
            MenuItemSaveAs: TMenuItem;
            MenuItemConvert: TMenuItem;
            MenuWindow: TMenuItem;
            MenuItemTextToMidi: TMenuItem;
            MenuItemMidiToText: TMenuItem;
            MenuHelp: TMenuItem;
            Notebook1: TNotebook;
            OpenDialog1: TOpenDialog;
            Page1: TPage;
            Page2: TPage;
            SaveDialog1: TSaveDialog;
            Separator3: TMenuItem;
            StatusBar1: TStatusBar;
            procedure ButtonConvert1Click(Sender: TObject);
            procedure ButtonConvert2Click(Sender: TObject);
            procedure FoldPosCheck(Sender: TObject);
            procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
            procedure FormShow(Sender: TObject);
            procedure MenuHideTextBoxClick(Sender: TObject);
            procedure MenuItemHelpClick(Sender: TObject);
            procedure MenuItemQuitClick(Sender: TObject);
            procedure MenuItemTextBoxClick(Sender: TObject);
            procedure MenuItemConvertClick(Sender: TObject);
            procedure MenuItemOpenClick(Sender: TObject);
            procedure MenuItemSaveAsClick(Sender: TObject);
            procedure SelectMidiInFile(Sender: TObject);
            procedure SelectMidiOutFile(Sender: TObject);
            procedure ButtonTextBoxInClick(Sender: TObject);
            procedure ButtonTextBoxOutClick(Sender: TObject);
            procedure ShowTextBox(Sender: TObject);
            procedure SwitchPage1(Sender: TObject);
            procedure SwitchPage2(Sender: TObject);
            procedure FormCreate(Sender: TObject);
            procedure SelectTextInFile(Sender: TObject);
            procedure SelectTextOutFile(Sender: TObject);

      private

      public

      end;

var
      Form1: TForm1;
      MidiFile: string;
      TextFile: string;
      TextStdInOut: Boolean;
      FPosValid: Boolean = True;
      FoldPos: string = '80';
      TextToMidi: Boolean = False;


implementation

{$R *.lfm}

{ TForm1 }


procedure SetStatus(msg: string);
begin
  Form1.StatusBar1.Panels[0].Text := msg;
end;


procedure ClearStatus;
begin
  SetStatus('');
end;

procedure CheckMF2TConvert;
begin
  if (MidiFile <> '') and ((TextFile <> '') or TextStdInOut) and FPosValid then
  begin
    Form1.ButtonConvert1.Enabled := True;
    Form1.MenuItemConvert.Enabled := True
    end
    else
  begin
    Form1.ButtonConvert1.Enabled := False;
    Form1.MenuItemConvert.Enabled := False
    end;
end;


procedure CheckT2MFConvert;
begin
  if (MidiFile <> '') and ((TextFile <> '') or
                          (TextStdInOut and Form2.validMidiText)) then
  begin
    Form1.ButtonConvert2.Enabled := True;
    Form1.MenuItemConvert.Enabled := True
    end
    else
  begin
    Form1.ButtonConvert2.Enabled := False;
    Form1.MenuItemConvert.Enabled := False
    end;
end;


{ Start MF2T conversion }

procedure ProcessOutput(proc: TProcess; StdoutStream, StderrStream: TMemoryStream);
const
  BUF_SIZE = 2048; // Buffer size for reading the output in chunks
var
  AvailableBytes, BytesRead: LongInt;
  Buffer: array[1..BUF_SIZE] of byte;

begin
  while proc.Running or
        (proc.Output.NumBytesAvailable > 0) or
        ((proc.Stderr <> nil) and (proc.Stderr.NumBytesAvailable > 0)) do
    begin
      // Check and read stdout
      AvailableBytes := proc.Output.NumBytesAvailable;
      if AvailableBytes > 0 then
      begin
        BytesRead := proc.Output.Read(Buffer, Min(BUF_SIZE, AvailableBytes));
        StdoutStream.Write(Buffer, BytesRead);
      end;
      // Check and read stderr
      if StderrStream <> nil then
      begin
                AvailableBytes := proc.Stderr.NumBytesAvailable;
            if AvailableBytes > 0 then
            begin
              BytesRead := proc.Stderr.Read(Buffer, Min(BUF_SIZE, AvailableBytes));
              StderrStream.Write(Buffer, BytesRead);
            end;
            end;
        end;
        Sleep(10);
end;


procedure FPosWarning;
begin
  if FPosValid then
    Form1.FPosWarningBox.Visible := False
  else
    begin
      Form1.FPosWarningBox.Caption := 'Position must be a number between 10 and 9999!';
      Form1.FPosWarningBox.Visible := True;
        end;
end;


procedure TForm1.ButtonConvert1Click(Sender: TObject);
const
  EXEC_PATH = '/Users/pieter/bin/'; // Temporary !!!
  {$IFDEF Windows}
    mf2t = 'mf2t.exe';
  {$ELSE}
    mf2t = 'mf2t';
  {$ENDIF Windows}

var
  //args: TStringList;
  proc: TProcess;
  StdoutStream, StderrStream: TMemoryStream;
  ErrorText: string;

begin
  ClearStatus;
  try
    proc := TProcess.Create(nil);

    proc.Executable := EXEC_PATH + mf2t;
    if CheckBoxOptionM.Checked then
      proc.Parameters.Add('-m');
    if CheckBoxOptionN.Checked then
      proc.Parameters.Add('-n');
    if CheckBoxOptionOn1.Checked then
      proc.Parameters.Add('-on');
    if CheckBoxOptionOff1.Checked then
      proc.Parameters.Add('-off');
    if CheckBoxOptionB.Checked then
      proc.Parameters.Add('-b');
    if CheckBoxOptionV.Checked then
      proc.Parameters.Add('-v');
    if CheckBoxOptionF.Checked then
    begin
      if not FPosValid then
      begin
        FPosWarning;
        Exit;
      end;
      proc.Parameters.Add('-f');
      proc.Parameters.Add(FoldPos);
    end;

    proc.Parameters.Add(MidiFile);
    if TextStdInOut then
      proc.Parameters.Add('-')
    else
      proc.Parameters.Add(TextFile);

    proc.Options := [poUsePipes, poNoConsole];
    proc.Execute;

    StdoutStream := TMemoryStream.Create;
    StderrStream := TMemoryStream.Create;
    ProcessOutput(proc, StdoutStream, StderrStream);

    // Process Stdout in case of TextBox
    if TextStdInOut then
    begin
      StdoutStream.Position := 0;
      Form2.setText(StdoutStream);  //assign text content
      Form2.Show;
    end;
    // Process Stderr
    StderrStream.Position := 0;
    with TStringList.Create do
      begin
        LoadFromStream(StderrStream);
        ErrorText := Text;
        if ErrorText <> '' then
          //ShowMessage(ErrorText);
          Application.MessageBox(PChar(ErrorText), 'Midi to Text',MB_ICONEXCLAMATION);
        Free;
      end;
    SetStatus('Conversion complete.');

  finally
      StdoutStream.Free;
      StderrStream.Free;
      proc.Free;
    end;

end;

procedure TForm1.SelectMidiInFile(Sender: TObject);
begin
  ClearStatus;
  OpenDialog1.Filter :=
      'Midi files (*.mid; *.midi)|*.mid; *.midi|All Files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    MidiFile := OpenDialog1.Filename;
    LabelMidiIn.Caption := MidiFile;
    CheckMF2TConvert;
  end
end;


procedure TForm1.SelectTextOutFile(Sender: TObject);
begin
  ClearStatus;
  SaveDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if SaveDialog1.Execute then
  begin
    TextFile := SaveDialog1.Filename;
    LabelTextOut.Caption := TextFile;
    TextStdInOut := False;
    MenuItemTextBox.checked := False;
    CheckMF2TConvert;
  end
end;


procedure TForm1.ButtonTextBoxOutClick(Sender: TObject);
begin
  ClearStatus;
  LabelTextOut.Caption := 'TextBox...';
  TextStdInOut := True;
  MenuItemTextBox.checked := True;
  Form2.CallBackProc := @CheckT2MFConvert;
  CheckMF2TConvert;
end;

procedure TForm1.ShowTextBox(Sender: TObject);
begin
  Form2.Show;
end;


{ PAGE 2 (text to midi) }

procedure TForm1.SelectTextInFile(Sender: TObject);
begin
  ClearStatus;
  OpenDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    TextFile := OpenDialog1.Filename;
    LabelTextIn.Caption := TextFile;
  //  MidiIn := True;
    TextStdInOut := False;
    MenuItemTextBox.checked := False;
    CheckT2MFConvert;
  end
end;


procedure TForm1.SelectMidiOutFile(Sender: TObject);
begin
  ClearStatus;
  SaveDialog1.Filter :=
      'Midi files (*.mid; *.midi)|*.mid; *.midi|All Files (*.*)|*.*';
  if SaveDialog1.Execute then
  begin
    MidiFile := SaveDialog1.Filename;
    LabelMidiOut.Caption := MidiFile;
    CheckT2MFConvert;
  end
end;


procedure TForm1.ButtonTextBoxInClick(Sender: TObject);
begin
  ClearStatus;
  LabelTextIn.Caption := 'TextBox...';
  TextStdInOut := True;
  MenuItemTextBox.checked := True;
  Form2.CallBackProc := @CheckT2MFConvert;
  Form2.Show;
  { trick to check if valid content in TextBox }
  Form2.SynEdit1.OnChange(Form2.SynEdit1);
  CheckT2MFConvert;
end;


procedure TForm1.ButtonConvert2Click(Sender: TObject);
const
  EXEC_PATH = '/Users/pieter/bin/'; // Temporary !!!
  {$IFDEF Windows}
    exe = 't2mf.exe';
  {$ELSE}
    exe = 't2mf';
  {$ENDIF Windows}

var
  //args: TStringList;
  proc: TProcess;
  StdoutStream: TMemoryStream;
  ErrorText: string;
  InputBytes: TBytes;
  bwait: Boolean;
  BytesWritten: Integer;

begin
  ClearStatus;
  try
    proc := TProcess.Create(nil);

    proc.Executable := EXEC_PATH + exe;
    if CheckBoxOptionR.Checked then
      proc.Parameters.Add('-r');
    if CheckBoxOptionOn1.Checked then
      proc.Parameters.Add('-on');
    if CheckBoxOptionOff1.Checked then
      proc.Parameters.Add('-off');

    if TextStdInOut then
      proc.Parameters.Add('-')
    else
      proc.Parameters.Add(TextFile);
    proc.Parameters.Add(MidiFile);

    proc.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    proc.Execute;

    if TextStdInOut then
    begin
      // Send TextBox content to stdin
      InputBytes := TEncoding.UTF8.GetBytes(Form2.SynEdit1.Text);
      BytesWritten := proc.Input.Write(InputBytes, Length(InputBytes));
      if BytesWritten <> Length(InputBytes) then
        ShowMessage('Write failed');
      proc.CloseInput;
      {$IFDEF UNIX}
        // On Unix systems the File Handle must also be closed
        // otherwise the process will not get EOF
        if (proc.Input <> nil) then
          fpClose(proc.Input.Handle);
      {$ENDIF}
        end;

    //bwait := proc.WaitOnExit;

        StdoutStream := TMemoryStream.Create;
    ProcessOutput(proc, StdoutStream, nil);

    // Process Stderr/Stdout
    StdoutStream.Position := 0;
    with TStringList.Create do
      begin
        LoadFromStream(StdoutStream);
        ErrorText := Text;
        if ErrorText <> '' then
          //ShowMessage(ErrorText);
          Application.MessageBox(PChar(ErrorText), 'Midi to Text',MB_ICONEXCLAMATION);
        Free;
      end;
    SetStatus('Conversion complete.');

  finally
      StdoutStream.Free;
      proc.Free;
    end;

end;


procedure TForm1.FoldPosCheck(Sender: TObject);
var
  LValue: LongInt;
  LText: string;
begin
  LText := Trim(Edit1.Text);
  Edit1.Text := LText;
  if LText = '' then
    LValue := 0
  else
   if not TryStrToInt(LText, LValue) then
     LValue:= 0;
  if (LValue < 10) or (LValue > 9999) then
    begin
      FPosValid := False;
      Edit1.SetFocus;
    end
  else
    begin
      FPosValid := True;
      FoldPos := LText;
    end;
  FPosWarning;
  CheckMF2TConvert;
end;


procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
      Form2.FormCloseQuery(Sender, CanClose);
end;

procedure TForm1.FormShow(Sender: TObject);
var
  AppMenu: TMenuItem;
begin
  {$IFDEF DARWIN}
    // On macOS, "Quit" is under the App menu.
    // Remove the "File -> Quit" item and the separator above.
    MenuFile.Remove(Separator3);
    MenuFile.Remove(MenuItemQuit);
    // Create Application menu
    AppMenu := TMenuItem.Create(Self);
    AppMenu.Caption := #$EF#$A3#$BF;
    MainMenu1.Items.Insert(0, AppMenu);
  {$ENDIF}
end;


procedure TForm1.MenuHideTextBoxClick(Sender: TObject);
begin
  Form2.Hide;
end;

procedure TForm1.MenuItemHelpClick(Sender: TObject);
begin
  OpenHelp;
  {
if not Assigned(HelpWindow) then
  Application.CreateForm(THelpWindow, HelpWindow);
  HelpWindow.Show();   }
end;


procedure TForm1.MenuItemQuitClick(Sender: TObject);
begin
      Self.Close;
end;


procedure TForm1.MenuItemTextBoxClick(Sender: TObject);
begin
  MenuItemTextBox.checked := not MenuItemTextBox.checked;
  if MenuItemTextBox.checked then
    if TextToMidi then
      ButtonTextBoxInClick(Sender)
    else
      ButtonTextBoxOutClick(Sender)
end;


procedure TForm1.MenuItemConvertClick(Sender: TObject);
begin
      { It is supposed that this can only be clicked
      if all the parameters are ready }
  If TextToMidi then
    ButtonConvert2Click(Sender)    { Text to Midi }
  else
    ButtonConvert1Click(Sender)     { Midi to Text }
end;


procedure TForm1.MenuItemOpenClick(Sender: TObject);
begin
      if TextToMidi then
        SelectTextInFile(Sender)
      else
        SelectMidiInfile(Sender)
end;


procedure TForm1.MenuItemSaveAsClick(Sender: TObject);
begin
      if TextToMidi then
        SelectMidiOutFile(Sender)
      else
        SelectTextOutFile(Sender)
end;


procedure LoadPage1;   { Midi To Text }
begin
  if Form1.Notebook1.PageIndex <> 0 then
  begin
    MidiFile := '';
    TextFile := '';
    TextStdInOut := False;
    FPosValid := True;
    Form1.ButtonConvert1.Enabled := False;
    Form1.Caption := 'Midi to Text';
    Form1.MenuItemMidiToText.Enabled := False;
    Form1.MenuItemTextToMidi.Enabled := True;
    Form1.MenuItemOpen.Caption := 'Select Input Midi File';
    Form1.MenuItemSaveAs.Caption := 'Select Output Text File';
    Form1.MenuItemTextBox.Caption := 'Output To TextBox';
    Form1.MenuItemTextBox.checked := False;
    end;
  Form1.Notebook1.PageIndex := 0;
  Form1.FPosWarningBox.Visible := False;
  TextToMidi := False;
  ClearStatus;
end;


procedure LoadPage2;   { Text To Midi }
begin
  if Form1.Notebook1.PageIndex <> 1 then
  begin
    MidiFile := '';
    TextFile := '';
    TextStdInOut := False;
    Form1.ButtonConvert2.Enabled := False;
    Form1.Caption := 'Text to Midi';
    Form1.MenuItemMidiToText.Enabled := True;
    Form1.MenuItemTextToMidi.Enabled := False;
    Form1.MenuItemOpen.Caption := 'Select Input Text File';
    Form1.MenuItemSaveAs.Caption := 'Select Output Midi File';
    Form1.MenuItemTextBox.Caption := 'Input From TextBox';
    Form1.MenuItemTextBox.checked := False;
    end;
  Form1.Notebook1.PageIndex := 1;
  TextToMidi := True;
  ClearStatus;
end;


procedure TForm1.SwitchPage1(Sender: TObject);
begin
  LoadPage1;
end;


procedure TForm1.SwitchPage2(Sender: TObject);
begin
  LoadPage2;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadPage1;
end;


initialization

end.

