unit MainForm;

{$mode objfpc}{$H+}

interface

uses
      {$IFDEF UNIX}
       BaseUnix, // Required for fpClose
      {$ENDIF}
      Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
			DBCtrls, TextBox, Process, LCLType, Menus, ComCtrls, Math;

type

			{ TForm1 }

      TForm1 = class(TForm)
						ButtonConvert2: TButton;
						ButtonMidiIn: TButton;
						ButtonTextInOut: TButton;
						ButtonTextboxOut: TButton;
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
						//LabelTextInOut: TLabel;
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
						MenuItem1: TMenuItem;
						MenuItem2: TMenuItem;
						MenuItem3: TMenuItem;
						MenuItem4: TMenuItem;
						MenuItem5: TMenuItem;
						MenuItem6: TMenuItem;
						MenuItem7: TMenuItem;
						MenuItem8: TMenuItem;
						Notebook1: TNotebook;
						OpenDialog1: TOpenDialog;
						Page1: TPage;
						Page2: TPage;
						SaveDialog1: TSaveDialog;
						StatusBar1: TStatusBar;
						procedure ButtonConvert1Click(Sender: TObject);
            procedure ButtonConvert2Click(Sender: TObject);
						procedure FoldPosCheck(Sender: TObject);
						procedure Page1BeforeShow(ASender: TObject; ANewPage: TPage;
									ANewIndex: Integer);
						procedure Page2BeforeShow(ASender: TObject; ANewPage: TPage;
									ANewIndex: Integer);
						procedure SelectMidiInFile(Sender: TObject);
						procedure SelectMidiOutFile(Sender: TObject);
						procedure ButtonTextboxInClick(Sender: TObject);
            procedure ButtonTextboxOutClick(Sender: TObject);
            procedure SwitchPage1(Sender: TObject);
						procedure SwitchPage2(Sender: TObject);
            procedure FormCreate(Sender: TObject);
						procedure SelectTextInFile(Sender: TObject);
            procedure SelectTextOutFile(Sender: TObject);
            //procedure Memo1Change(Sender: TObject);

      private
      {VAR
      MidiFile: string;
      TextFile: string;
      MidiIn, TextInOut: Boolean;
      TextStdInOut: Boolean;
      FPosValid: Boolean;     }

      public

      end;

var
      Form1: TForm1;
      MidiFile: string;
      TextFile: string;
      TextStdInOut: Boolean;
      FPosValid: Boolean = True;
      FoldPos: string = '80';


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
    Form1.ButtonConvert1.Enabled := True
  else
    Form1.ButtonConvert1.Enabled := False
end;


procedure CheckT2MFConvert;
begin
  if (MidiFile <> '') and ((TextFile <> '') or
                          (TextStdInOut and Form2.validMidiText)) then
    Form1.ButtonConvert2.Enabled := True
  else
    Form1.ButtonConvert2.Enabled := False
end;


{ Start MF2T conversion }

procedure ProcessStdoutStderr(proc: TProcess; StdoutStream, StderrStream: TMemoryStream);
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
    ProcessStdoutStderr(proc, StdoutStream, StderrStream);

    // Process Stdout in case of TextBox
    if TextStdInOut then
    begin
      StdoutStream.Position := 0;
      with TStringList.Create do
        begin
          LoadFromStream(StdoutStream);
          Form2.setText(Text);  //assign text content
          Form2.Show;
          Free;
        end;
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
  //  MidiIn := True;
    CheckMF2TConvert;
  	//ShowMessage('File selected: ' + filename);
  end
end;


procedure TForm1.SelectTextOutFile(Sender: TObject);
var filename: string;
begin
  ClearStatus;
  SaveDialog1.Filter :=
      'Text Files (*.txt; *.text)|*.txt; *.text|All Files (*.*)|*.*';
  if SaveDialog1.Execute then
  begin
    TextFile := SaveDialog1.Filename;
    LabelTextOut.Caption := TextFile;
    TextStdInOut := False;
    CheckMF2TConvert;
  	//ShowMessage('File selected: ' + filename);
  end
end;


procedure TForm1.ButtonTextboxOutClick(Sender: TObject);
begin
  ClearStatus;
  LabelTextOut.Caption := 'TextBox...';
  TextStdInOut := True;
  Form2.CallBackProc := @CheckT2MFConvert;
  CheckMF2TConvert;
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
    CheckT2MFConvert;
  	//ShowMessage('File selected: ' + filename);
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
  	//ShowMessage('File selected: ' + filename);
  end
end;


procedure TForm1.ButtonTextboxInClick(Sender: TObject);
begin
  ClearStatus;
  LabelTextIn.Caption := 'TextBox...';
  TextStdInOut := True;
  Form2.CallBackProc := @CheckT2MFConvert;
  Form2.Show;
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
      InputBytes := TEncoding.UTF8.GetBytes(Form2.Memo1.Text);
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
    ProcessStdoutStderr(proc, StdoutStream, nil);

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


procedure TForm1.Page1BeforeShow(ASender: TObject; ANewPage: TPage;
			ANewIndex: Integer);
begin

end;

procedure TForm1.Page2BeforeShow(ASender: TObject; ANewPage: TPage;
			ANewIndex: Integer);
begin

end;


procedure LoadPage1;
begin
  if Form1.Notebook1.PageIndex <> 0 then
  begin
  	MidiFile := '';
    TextFile := '';
    TextStdInOut := False;
    FPosValid := True;
    Form1.ButtonConvert1.Enabled := False;
    Form1.Caption := 'Midi to Text';
	end;
  Form1.Notebook1.PageIndex := 0;
  Form1.FPosWarningBox.Visible := False;
end;


procedure LoadPage2;
begin
  if Form1.Notebook1.PageIndex <> 1 then
  begin
  	MidiFile := '';
    TextFile := '';
    TextStdInOut := False;
    Form1.ButtonConvert2.Enabled := False;
    Form1.Caption := 'Text to Midi';

	end;
  Form1.Notebook1.PageIndex := 1;
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

