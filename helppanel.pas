unit HelpPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, strutils,
  Dialogs, IpHtml, IpHtmlNodes, IpUtils, Ipfilebroker, lclintf;

type

  { TIpHtmlPanelH }

  TIpHtmlPanelH = class(TIpHtmlPanel)
  private
    procedure HotClickH(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;

  end;

  { THelpWindow }

  THelpWindow = class(TForm)
	  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);

  private
    procedure ForceRefreshHtml(Data: PtrInt);
    var
      IpHtmlPanel: TIpHtmlPanelH;

  public
      
  end;


    { TMyFileDataProvider }

    TMyFileDataProvider = class(TIpFileDataProvider)
      function BuildURL(const Old, New : string) : string; override;
    end;


var
  HelpWindow: THelpWindow;

procedure OpenHelp;

implementation

{$R *.lfm}

// temporary location
const
  DocFile ='/Users/pieter/TEST/PASCAL/DOC/index.html';

{ TIpHtmlPanelH }

procedure TIpHtmlPanelH.HotClickH(Sender: TObject);
var
  URL: string;
begin
  begin
    URL := HotURL;
    // Open external links in external browser
    if StartsText('http://', URL) or StartsText('https://', URL) then
      begin
        lclintf.OpenURL(URL);
	    end;
  end;
end;


constructor TIpHtmlPanelH.Create(AOwner: TComponent);
begin
  inherited;
  OnHotClick := @HotClickH;
end;


  { THelpWindow }

procedure THelpWindow.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  HelpWindow.Release;
  HelpWindow := nil;
end;


procedure THelpWindow.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Hide;
  IpHtmlPanel := TIpHtmlPanelH.Create(Application);
  with IpHtmlPanel do
  begin
    Parent := Self;
    Align := alClient;
    DataProvider := TMyFileDataProvider.Create(Self);
    OpenURL(DocFile);
    // This is to avoid a bug (maybe macOS specific)
    // where the text is initially positioned too high,
    // probably caused by a timing issue between calculating
    // the text position and inserting the scrollbars.
    Application.QueueAsyncCall(@ForceRefreshHtml, 0);
	end;
end;


procedure THelpWindow.ForceRefreshHtml(Data: PtrInt);
begin
  // Force the panel to reformat
  IpHtmlPanel.Repaint;
  Show;
end;


  { TMyFileDataProvider }


{ We override BuildURL because the one in iputils is broken,
  and we just need a simple one.
  This only works for local files, not for URLS with a scheme.
  TODO: Check if this works on Windows, with drive letters.
}

function TMyFileDataProvider.BuildURL(const Old, New : string) : string;
begin
  if (New <> '') and (New[1] <> '/') then
    Result := AppendSlash(ExtractEntityPath(Old)) + New
  else
    Result := New;
    //writeln('Old = ', Old, ', New = ', New, ', BuildURL => ', Result);
end;

procedure OpenHelp;
begin
  if not Assigned(HelpWindow) then
  begin
    Application.CreateForm(THelpWindow, HelpWindow);
  end;
  HelpWindow.Show;
end;


end.

