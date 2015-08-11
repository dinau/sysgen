{-----------------------------------------------------------------------------}
{ TBrowseDirectoryDlg v2.37                                                   }
{-----------------------------------------------------------------------------}
{ A component to encapsulate the Win95 style directory selection dialog       }
{ SHBrowseForFolder().                                                        }
{ Copyright 1996, Brad Stowers.  All Rights Reserved.                         }
{ This component can be freely used and distributed in commercial and private }
{ environments, provied this notice is not modified in any way and there is   }
{ no charge for it other than nomial handling fees.  Contact me directly for  }
{ modifications to this agreement.                                            }
{-----------------------------------------------------------------------------}
{ Feel free to contact me if you have any questions, comments or suggestions  }
{ at bstowers@pobox.com.                                                      }
{ The lateset version will always be available on the web at:                 }
{   http://www.pobox.com/~bstowers/delphi/                                    }
{ See BrowseDr.txt for notes, known issues, and revision history.             }
{-----------------------------------------------------------------------------}
{ Date last modified:  May 13, 1998                                           }
{-----------------------------------------------------------------------------}


{: This unit provides a component that displays a standard Windows 95/NT 4...
   dialog containing the user's system in a heirarchial manner and allows a...
   selection to be made.  It is a wrapper for the SHBrowseForFolder() API,...
   which is quite messy to use directly.  Also provided is an editor which...
   allows you to display the dialog at design time with the selected options.

   Note:
   This component Requires Delphi 3 or Delphi v2.01's ShlObj unit.  If you...
   have Delphi 2.00, you can get the equivalent using Pat Ritchey's ShellObj...
   unit.  It is freely available on his web site at...
   http://ourworld.compuserve.com/homepages/PRitchey/.  Both Borland's ShlObj...
   unit and Pat's ShellObj unit contain errors that should be fixed.  I have...
   included instructions on how to do this.  They are in the included...
   ShellFix.txt file.  Delphi 3's ShlObj unit does not have any errors that I...
   am currently aware of.
}


// C++Builder 3 requires this if you use run-time packages.
{$IFDEF DFS_CPPB_3_UP}
  {$ObjExportAll On}
{$ENDIF}

unit cDialogs;


interface

{$IFDEF DFS_CPPB_3_UP}
  {$R BrowseDr.dcr}
{$ENDIF}

uses
  Windows, Dialogs,
  ActiveX,ShlObj, { Delphi 3 fixes all of 2.01's bugs! }
  Controls, Classes{, DsgnIntf};

const
  {: This is a newly documented folder identifier that is not in the Delphi...
     units yet.  You can use it with any of the Win32 Shell API functions...
      that wants a CSIDL_* identifier such as SHGetSpecialFolderLocation. }

  { This shuts C++Builder 3 up about the redefiniton being different. There
    seems to be no equivalent in C1.  Sorry. }
  {$IFDEF DFS_CPPB_3_UP}
  {$EXTERNALSYM CSIDL_INTERNET}
  {$ENDIF}
  CSIDL_INTERNET         = $0001;
{$IFNDEF DFS_COMPILER_3}
  { IDs that exist in Delphi/C++B 3 ShlObj.pas unit, but not Delphi 2. }
  CSIDL_COMMON_STARTMENU              = $0016;
  CSIDL_COMMON_PROGRAMS               = $0017;
  CSIDL_COMMON_STARTUP                = $0018;
  CSIDL_COMMON_DESKTOPDIRECTORY       = $0019;
  CSIDL_APPDATA                       = $001a;
  CSIDL_PRINTHOOD                     = $001b;
{$ENDIF}

  {: This folder identifer is undocumented, but should work for a long time...
     since the highest ID is currently around 30 or so.  It is used to open...
     the tree already expanded with the desktop as the root item. }
  CSIDL_DESKTOPEXPANDED  = $FEFE;
{$IFNDEF DFS_COMPILER_3}
  {: This constant was missing from the Delphi 2 units, but was added to...
     Delphi 3.  It causes files to be included in the tree as well as folders. }
  BIF_BROWSEINCLUDEFILES = $4000;
{$ENDIF}

type
  {: This enumerated type is the equivalent of the CSIDL_* constants in the...
     Win32 API. They are used to specify the root of the heirarchy tree.

    idDesktop: Windows desktop -- virtual folder at the root of the name space.
    idInternet: Internet Explorer -- virtual folder of the Internet Explorer.
    idPrograms: File system directory that contains the user's program groups...
       (which are also file system directories).
    idControlPanel: Control Panel -- virtual folder containing icons for the...
       control panel applications.
    idPrinters: Printers folder -- virtual folder containing installed printers.
    idPersonal: File system directory that serves as a common respository for...
       documents.
    idFavorites: Favorites folder -- virtual folder containing the user's...'
       Internet Explorer bookmark items and subfolders.
    idStartup: File system directory that corresponds to the user's Startup...
       program group.
    idRecent: File system directory that contains the user's most recently...
       used documents.
    idSendTo: File system directory that contains Send To menu items.
    idRecycleBin: Recycle bin -- file system directory containing file...
       objects in the user's recycle bin. The location of this directory is...
       not in the registry; it is marked with the hidden and system...
       attributes to prevent the user from moving or deleting it.
    idStartMenu: File system directory containing Start menu items.
    idDesktopDirectory: File system directory used to physically store file...
       objects on the desktop (not to be confused with the desktop folder itself).
    idDrives: My Computer -- virtual folder containing everything on the...
       local computer: storage devices, printers, and Control Panel. The...
       folder may also contain mapped network drives.
    idNetwork: Network Neighborhood -- virtual folder representing the top...
       level of the network hierarchy.
    idNetHood: File system directory containing objects that appear in the...
       network neighborhood.
    idFonts: Virtual folder containing fonts.
    idTemplates: File system directory that serves as a common repository for...
       document templates.
    idCommonStartMenu: File system directory that contains the programs and...
       folders that appear on the Start menu for all users on Windows NT.
    idCommonPrograms: File system directory that contains the directories for...
       the common program groups that appear on the Start menu for all users...
       on Windows NT.
    idCommonStartup: File system directory that contains the programs that...
       appear in the Startup folder for all users. The system starts these...
       programs whenever any user logs on to Windows NT.
    idCommonDesktopDirectory: File system directory that contains files and...
       folders that appear on the desktop for all users on Windows NT.
    idAppData: File system directory that contains data common to all...
       applications.
    idPrintHood: File system directory containing object that appear in the...
       printers folder.
    idDesktopExpanded: Same as idDesktop except that the root item is already...
       expanded when the dialog is initally displayed.

    NOTE: idCommonStartMenu, idCommonPrograms, idCommonStartup, and...
       idCommonDesktopDirectory only have effect when the dialog is being...
       displayed on an NT system.  On Windows 95, these values will be...
       mapped to thier "non-common" equivalents, i.e. idCommonPrograms will...
       become idPrograms.
  }

  TViewRoot = (
    vrDesktop, vrInternet, vrPrograms, vrControlPanel, vrPrinters, vrPersonal,
    vrFavorites, vrStartup, vrRecent, vrSendTo, vrRecycleBin, vrStartMenu,
    vrDesktopDirectory, vrDrives, vrNetwork, vrNetHood, vrFonts, vrTemplates,
    vrCommonStartMenu, vrCommonPrograms, vrCommonStartup,
    vrCommonDesktopDirectory, vrAppData, vrPrintHood, vrDesktopExpanded
   );

  {: These are equivalent to the BIF_* constants in the Win32 API.  They are...
     used to specify what items can be expanded, and what items can be...
     selected by combining them in a set in the Options property.

     bfDirectoriesOnly: Only returns file system directories. If the user...
        selects folders that are not part of the file system, the OK button...
        is grayed.
     bfDomainOnly: Does not include network folders below the domain level...
        in the dialog.
     bfAncestors: Only returns file system ancestors (items which contain...
        files, like drives).  If the user selects anything other than a file...
        system ancestor, the OK button is grayed.
     bfComputers: Shows other computers.  If anything other than a computer...
        is selected, the OK button is disabled.
     bfPrinters:	Shows all printers.  If anything other than a printers is...
        selected, the OK button is disabled.
     bfIncludeFiles: Show non-folder items that exist in the folders.
  }
  TBrowseType = (
    btDirectoriesOnly, btDomainOnly, btAncestors, btComputers, btPrinters,
    btIncludeFiles
   );

  {: A set of TBrowseType items. }
  TBrowseTypes = set of TBrowseType;

  { TBDSelChangedEvent is used for events associated with...
    TFolderDlg's OnSelChanged event.

    The Sender parameter is the TFolderDlg object whose event handler...
    is called.  The NewSel parameter is the text representation of the new...
    selection.  The NewSelPIDL is the new PItemIDList representation of the...
    new selection. }
  TBDSelChangedEvent = procedure(Sender: TObject; NewSel: string;
     NewSelPIDL: PItemIDList) of object;

type
  {: TFolderDlg provides a component that displays a standard...
     Windows 95/NT 4 dialog containing the user's system in a heirarchial...
     manner and allows a selection to be made.  It is a wrapper for the...
     SHBrowseForFolder() API, which is quite messy to use directly. }
  TFolderDlg = class(TComponent)
  private
    { Internal variables }
    FDlgWnd: HWND;
    { Property variables }
    FCaption: string;
    FParent: TWinControl;
    FShowSelectionInStatus: boolean;
    FFitStatusText: boolean;
    FTitle: string;
    FRoot: TViewRoot;
    FOptions: TBrowseTypes;
    FSelection: string;
    FCenter: boolean;
    FStatusText: string;
    FEnableOKButton: boolean;
    FImageIndex: integer;
    FSelChanged: TBDSelChangedEvent;
    FOnCreate: TNotifyEvent;
		FSelectionPIDL: PItemIDList;
    FShellMalloc: IMalloc;
    FDisplayName: string;
		function GetDisplayName: string;
  protected
    // internal methods
    function FittedStatusText: string;
    procedure SendSelectionMessage;
    // internal event methods.
    procedure DoInitialized(Wnd: HWND); virtual;
    procedure DoSelChanged(Wnd: HWND; Item: PItemIDList); virtual;
    // property methods
    procedure SetFitStatusText(Val: boolean);
    procedure SetStatusText(const Val: string);
    procedure SetSelection(const Val: string);
		procedure SetSelectionPIDL(Value: PItemIDList);
    procedure SetEnableOKButton(Val: boolean);
    function GetCaption: string;
    procedure SetCaption(const Val: string);
    procedure SetParent(AParent: TWinControl);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {: Displays the browser folders dialog.  It returns TRUE if user selected...
       an item and pressed OK, otherwise it returns FALSE. }
    function Execute: boolean; virtual;

    {: The window component that is the browse dialog's parent window.  By...
       assigning a value to this property, you can control the parent window...
       independant of the form that the component exists on.

       You do not normally need to assign any value to this property as it...
       will use the form that contains the component by default. }
    property Parent: TWinControl read FParent write SetParent;
    {: An alternative to the Selection property.  Use this property if the...
       item you are interested in does not have a path (Control Panels, for...
       example).  The most common way to retrieve a value for this property...
       is to use the SHGetSpecialFolderLocation Windows API function. Once...
       you have assigned a value to this property, it is "owned" by the...
       component.  That is, the component will take care of freeing it when...
       it is no longer needed.

       When setting this property before calling the Execute method, it will...
       only be used if the Selection property is blank.  If Selection is not...
       blank, it will be used instead.

       Upon return from the Execute method, this property will contain the...
       PItemIDList of the item the user selected.  In some cases, this will...
       the only way to get the user's choice since items such as Control...
       Panel do not have a string that can be placed in the Selection property.}
		property SelectionPIDL: PItemIDList read FSelectionPIDL
       write SetSelectionPIDL;
    {: DisplayName is run-time, read-only property that returns the display...
       name of the selection.  It only has meaning after the dialog has been...
       executed and the user has made a selection.  It returns the "human...
       readable" form of the selection.  This generally is the same as the...
       Selection property when it is a file path, but in the case of items...
       such as the Control Panel which do not have a path, Selection is blank.
       In this case, the only way to access the users' selection is to use...
       the SelectionPIDL property.  That doesn't provide an easy way of...
       presenting a textual representation of what they chose, but this...
       property will do that for you.

       If, for example, the user chose the Control Panel folder, the Selection...
       property would be blank, but DisplayName would be "Control Panel".  You...
       could not actually use this value to get to the Control Panel, for that...
       you need to use the SelectionPIDL property and various Shell Namespace...
       API functions. }
		property DisplayName: string read GetDisplayName;
  published
    {: The selected item in the browse folder dialog.

       Setting this before calling the Execute method will cause the assigned...
       value to be initially selected when the dialog is initially displayed...
       if the item exists.  If it does not exist, the root item will be selected.

       If this value is blank, the SelectionPIDL item will be used instead.

       After the Execute method returns, you can read this value to determine...
       what item the user selected, unless that item does not have a string...
       representation (Control Panel, for example). }
    property Selection: string read FSelection write SetSelection;
    {: Specifies the text to appear at the top of the dialog above the tree...
       control.  There is enough room for two lines of text, and it will be...
       word-wrapped for you automatically.

       Generally, this is used to provide user instructions or as a title for
       the StatusText property.

       Example:

       // Title property set to "The current selection is:"
       procedure TForm1.BrowseDirectoryDlgSelChanged(Sender: TObject; const NewSel: string);
       begin
         // NewSel has the full selection
         BrowseDirectoryDlg.StatusText := NewSel;
       end;
    }
    property Title: string read FTitle write FTitle;
    {: Specifies the item that is to be treated as the root of the tree...
       display.

    idDesktop: Windows desktop -- virtual folder at the root of the name space.
    idInternet: Internet Explorer -- virtual folder of the Internet Explorer.
    idPrograms: File system directory that contains the user's program groups...
       (which are also file system directories).
    idControlPanel: Control Panel -- virtual folder containing icons for the...
       control panel applications.
    idPrinters: Printers folder -- virtual folder containing installed printers.
    idPersonal: File system directory that serves as a common respository for...
       documents.
    idFavorites: Favorites folder -- virtual folder containing the user's...'
       Internet Explorer bookmark items and subfolders.
    idStartup: File system directory that corresponds to the user's Startup...
       program group.
    idRecent: File system directory that contains the user's most recently...
       used documents.
    idSendTo: File system directory that contains Send To menu items.
    idRecycleBin: Recycle bin -- file system directory containing file...
       objects in the user's recycle bin. The location of this directory is...
       not in the registry; it is marked with the hidden and system...
       attributes to prevent the user from moving or deleting it.
    idStartMenu: File system directory containing Start menu items.
    idDesktopDirectory: File system directory used to physically store file...
       objects on the desktop (not to be confused with the desktop folder itself).
    idDrives: My Computer -- virtual folder containing everything on the...
       local computer: storage devices, printers, and Control Panel. The...
       folder may also contain mapped network drives.
    idNetwork: Network Neighborhood -- virtual folder representing the top...
       level of the network hierarchy.
    idNetHood: File system directory containing objects that appear in the...
       network neighborhood.
    idFonts: Virtual folder containing fonts.
    idTemplates: File system directory that serves as a common repository for...
       document templates.
    idCommonStartMenu: File system directory that contains the programs and...
       folders that appear on the Start menu for all users on Windows NT.
    idCommonPrograms: File system directory that contains the directories for...
       the common program groups that appear on the Start menu for all users...
       on Windows NT.
    idCommonStartup: File system directory that contains the programs that...
       appear in the Startup folder for all users. The system starts these...
       programs whenever any user logs on to Windows NT.
    idCommonDesktopDirectory: File system directory that contains files and...
       folders that appear on the desktop for all users on Windows NT.
    idAppData: File system directory that contains data common to all...
       applications.
    idPrintHood: File system directory containing object that appear in the...
       printers folder.
    idDesktopExpanded: Same as idDesktop except that the root item is already...
       expanded when the dialog is initally displayed.

    NOTE: idCommonStartMenu, idCommonPrograms, idCommonStartup, and...
       idCommonDesktopDirectory only have effect when the dialog is being...
       displayed on an NT system.  On Windows 95, these values will be...
       mapped to thier "non-common" equivalents, i.e. idCommonPrograms will...
       become idPrograms.
    }
    property Root: TViewRoot read FRoot write FRoot default vrDesktop;
    {: Options is a set of TBrowseType items that controls what is allowed to...
       be selected and expanded in the tree.  It can be a combination of any...
       (or none) of the following:

     bfDirectoriesOnly: Only returns file system directories. If the user...
        selects folders that are not part of the file system, the OK button...
        is grayed.
     bfDomainOnly: Does not include network folders below the domain level...
        in the dialog.
     bfAncestors: Only returns file system ancestors (items which contain...
        files, like drives).  If the user selects anything other than a file...
        system ancestor, the OK button is grayed.
     bfComputers: Shows other computers.  If anything other than a computer...
        is selected, the OK button is disabled.
     bfPrinters:	Shows all printers.  If anything other than a printers is...
        selected, the OK button is disabled.
     bfIncludeFiles: Show non-folder items that exist in the folders.
    }
    property Options: TBrowseTypes read FOptions write FOptions default [];
    {: Indicates whether the dialog should be centered on the screen or shown...
      in a default, system-determined location. }
    property Center: boolean read FCenter write FCenter default TRUE;
    {: A string that is displayed directly above the tree view control and...
       just under the Title text in the dialog box. This string can be used...
       for any purpose such as to specify instructions to the user, or show...
       the full path of the currently selected item.  You can modify this...
       value while the dialog is displayed from the the OnSelChanged event.

       If StatusText is blank when the Execute method is called, the dialog...
       will not have a status text area and assigning to the StatusText...
       property will have no effect.

       Example:

       // Title property set to "The current selection is:"
       procedure TForm1.BrowseDirectoryDlgSelChanged(Sender: TObject; const NewSel: string);
       begin
         // NewSel has the full selection
         BrowseDirectoryDlg.StatusText := NewSel;
       end;
       }
    property StatusText: string read FStatusText write SetStatusText;
    {: Indicates whether the StatusText string should be shortened to make it...
       fit in available status text area.  The status text area is only large...
       enough to hold one line of text, and if the text is too long for the...
       available space, it will simply be chopped off.  However, if this...
       property is set to TRUE, the text will be shortened using an ellipsis...
       ("...").

       For example, if the status text property were...
       "C:\Windows\Start Menu\Programs\Applications\Microsoft Reference", it
       could be shortened to...
       "C:\...\Start Menu\Programs\Applications\Microsoft Reference" depending
       on the screen resolution and dialog font size.
    }
    property FitStatusText: boolean read FFitStatusText write SetFitStatusText
       default TRUE;
    {: This property enables or disables the OK button on the browse folders...
       dialog.  This allows control over whether a selection can be made or...
       not. You can modify this value while the dialog is displayed from the...
       the OnSelChanged event.  This allows you to control whether the user...
       can select an item based on what the current selection is.

       Example:
       procedure TForm1.BrowseDirectoryDlgSelChanged(Sender: TObject; const NewSel: string);
       begin
         // NewSel has the full selection.  Only allow items greater than 10 characters to be selected.
         BrowseDirectoryDlg.EnableOKButton := Length(NewSel > 10);
       end;
    }
    property EnableOKButton: boolean read FEnableOKButton write SetEnableOKButton
       default TRUE;
    {: After a selection has been made in the dialog, this property will...
       contain the index into the system image list of the selected node. See...
       the demo application for an example how this can be used. }
    property ImageIndex: integer read FImageIndex;
    {: Specifies the text in the dialog's caption bar. Use Caption to specify...
       the text that appears in the browse folder dialog's title bar. If no...
       value is assigned to Title, the dialog has a title based on the...
       Options property.

       For example, if bfPrinters was set, the title would be "Browse for...
       Printer". }
    property Caption: string read GetCaption write SetCaption;
    {: Automatically shows the current selection in the status text area of...
       the dialog.  }
    property ShowSelectionInStatus: boolean read FShowSelectionInStatus
       write FShowSelectionInStatus;
    {: The OnSelChange event is fired every time a new item is selected in...
       the tree.

      The Sender parameter is the TFolderDlg object whose event...
      handler is called.  The NewSel parameter is the text representation of...
      the new selection.  The NewSelPIDL is the new PItemIDList...
      representation of the new selection.

      NOTE:  You will need to add ShlObj to your uses clause if you define...
      a handler for this event. }
    property OnSelChanged: TBDSelChangedEvent read FSelChanged write FSelChanged;
    { The OnCreate event is fired when dialog has been created, but just...
       before it is displayed to the user. }
    property OnCreate: TNotifyEvent read FOnCreate write FOnCreate;
  end;

{ Utility function you may find useful }
function DirExists(const Dir: string): boolean;

implementation

uses Forms, SysUtils, Messages;

// Utility functions used to convert from Delphi set types to API constants.
function ConvertRoot(Root: TViewRoot): integer;
const
  WinNT_RootValues: array[TViewRoot] of integer = (
    CSIDL_DESKTOP, CSIDL_INTERNET, CSIDL_PROGRAMS, CSIDL_CONTROLS,
    CSIDL_PRINTERS, CSIDL_PERSONAL, CSIDL_FAVORITES, CSIDL_STARTUP,
    CSIDL_RECENT, CSIDL_SENDTO, CSIDL_BITBUCKET, CSIDL_STARTMENU,
    CSIDL_DESKTOPDIRECTORY, CSIDL_DRIVES, CSIDL_NETWORK, CSIDL_NETHOOD,
    CSIDL_FONTS, CSIDL_TEMPLATES, CSIDL_COMMON_STARTMENU, CSIDL_COMMON_PROGRAMS,
    CSIDL_COMMON_STARTUP, CSIDL_COMMON_DESKTOPDIRECTORY, CSIDL_APPDATA,
    CSIDL_PRINTHOOD, CSIDL_DESKTOPEXPANDED
  );
  Win95_RootValues: array[TViewRoot] of integer = (
    CSIDL_DESKTOP, CSIDL_INTERNET, CSIDL_PROGRAMS, CSIDL_CONTROLS,
    CSIDL_PRINTERS, CSIDL_PERSONAL, CSIDL_FAVORITES, CSIDL_STARTUP,
    CSIDL_RECENT, CSIDL_SENDTO, CSIDL_BITBUCKET, CSIDL_STARTMENU,
    CSIDL_DESKTOPDIRECTORY, CSIDL_DRIVES, CSIDL_NETWORK, CSIDL_NETHOOD,
    CSIDL_FONTS, CSIDL_TEMPLATES, CSIDL_STARTMENU, CSIDL_PROGRAMS,
    CSIDL_STARTUP, CSIDL_DESKTOPDIRECTORY, CSIDL_APPDATA, CSIDL_PRINTHOOD,
    CSIDL_DESKTOPEXPANDED
  );
var
  VerInfo: TOSVersionInfo;
begin
  VerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(VerInfo);
  if VerInfo.dwPlatformId = VER_PLATFORM_WIN32_NT then
    Result := WinNT_RootValues[Root]
  else
    Result := Win95_RootValues[Root];
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function ConvertFlags(Flags: TBrowseTypes): UINT;
const
  FlagValues: array[TBrowseType] of UINT = (
    BIF_RETURNONLYFSDIRS, BIF_DONTGOBELOWDOMAIN, BIF_RETURNFSANCESTORS,
    BIF_BROWSEFORCOMPUTER, BIF_BROWSEFORPRINTER, BIF_BROWSEINCLUDEFILES
   );
var
  Opt: TBrowseType;
begin
  Result := 0;
  { Loop through all possible values }
  for Opt := Low(TBrowseType) to High(TBrowseType) do
    if Opt in Flags then
      Result := Result OR FlagValues[Opt];
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function GetTextWidth(DC: HDC; const Text: String): Integer;
var
  Extent: TSize;
begin
  if GetTextExtentPoint(DC, PChar(Text), Length(Text), Extent) then
    Result := Extent.cX
  else
    Result := 0;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function MinimizeName(Wnd: HWND; const Filename: string): string;

  procedure CutFirstDirectory(var S: string);
  var
    Root: Boolean;
    P: Integer;
  begin
    if S = '\' then
      S := ''
    else begin
      if S[1] = '\' then begin
        Root := True;
        Delete(S, 1, 1);
      end else
        Root := False;
      if S[1] = '.' then
        Delete(S, 1, 4);
      P := Pos('\',S);
      if P <> 0 then begin
        Delete(S, 1, P);
        S := '...\' + S;
      end else
        S := '';
      if Root then
        S := '\' + S;
    end;
  end;

var
  Drive: string;
  Dir: string;
  Name: string;
  R: TRect;
  DC: HDC;
  MaxLen: integer;
  OldFont, Font: HFONT;
begin
  Result := FileName;
  if Wnd = 0 then exit;
  DC := GetDC(Wnd);
  if DC = 0 then exit;
  Font := SendMessage(Wnd, WM_GETFONT, 0, 0);
  OldFont := SelectObject(DC, Font);
  try
    GetWindowRect(Wnd, R);
    MaxLen := R.Right - R.Left;

    Dir := ExtractFilePath(Result);
    Name := ExtractFileName(Result);

    if (Length(Dir) >= 2) and (Dir[2] = ':') then begin
      Drive := Copy(Dir, 1, 2);
      Delete(Dir, 1, 2);
    end else
      Drive := '';
    while ((Dir <> '') or (Drive <> '')) and (GetTextWidth(DC, Result) > MaxLen) do begin
      if Dir = '\...\' then begin
        Drive := '';
        Dir := '...\';
      end else if Dir = '' then
        Drive := ''
      else
        CutFirstDirectory(Dir);
      Result := Drive + Dir + Name;
    end;
  finally
    SelectObject(DC, OldFont);
    ReleaseDC(Wnd, DC);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function MinimizeString(Wnd: HWND; const Text: string): string;
var
  R: TRect;
  DC: HDC;
  MaxLen: integer;
  OldFont, Font: HFONT;
  TempStr: string;
begin
  Result := Text;
  TempStr := Text;
  if Wnd = 0 then exit;
  DC := GetDC(Wnd);
  if DC = 0 then exit;
  Font := SendMessage(Wnd, WM_GETFONT, 0, 0);
  OldFont := SelectObject(DC, Font);
  try
    GetWindowRect(Wnd, R);
    MaxLen := R.Right - R.Left;
    while (TempStr <> '') and (GetTextWidth(DC, Result) > MaxLen) do begin
      SetLength(TempStr, Length(TempStr)-1);
      Result := TempStr + '...';
    end;
  finally
    SelectObject(DC, OldFont);
    ReleaseDC(Wnd, DC);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function DirExists(const Dir: string): boolean;
  function StripTrailingBackslash(const Dir: string): string;
  begin
    Result := Dir;
    // Make sure we have a string, and if so, see if the last char is a \
    if (Result <> '') and (Result[Length(Result)] = '\') then
      SetLength(Result, Length(Result)-1); // Shorten the length by one to remove
  end;
var
  Tmp: string;
  DriveBits: set of 0..25;
  SR: TSearchRec;
  Found: boolean;
begin
  if (Length(Dir) = 3) and (Dir[2] = ':') and (Dir[3] = '\') then begin
    Integer(DriveBits) := GetLogicalDrives;
    Tmp := UpperCase(Dir[1]);
    Result := (ord(Tmp[1]) - ord('A')) in DriveBits;
  end else begin
    Found := FindFirst(StripTrailingBackslash(Dir), faDirectory, SR) = 0;
    Result := Found and (Dir <> '');
    if Result then
      Result := (SR.Attr and faDirectory) = faDirectory;
    if Found then
      // only call FinClose if FindFirst succeeds.  Can lock NT up if it didn't
      FindClose(SR);
  end;
end; // DirExists
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function BrowseCallbackProc(Wnd: HWnd; Msg: UINT; lParam: LPARAM; lData: LPARAM): integer; stdcall;
begin
  Result := 0;
  case Msg of
    BFFM_INITIALIZED:
      if lData <> 0 then
        TFolderDlg(lData).DoInitialized(Wnd);
    BFFM_SELCHANGED:
      if lData <> 0 then
        TFolderDlg(lData).DoSelChanged(Wnd, PItemIDList(lParam));
  end;
end;


(*
function CopyPIDL(ShellMalloc: IMalloc; AnID: PItemIDList): PItemIDList;
var
  Size: integer;
begin
  Size := 0;
  if AnID <> NIL then
  begin
    while AnID.mkid.cb > 0 do
    begin
      Inc(Size, AnID.mkid.cb  + SizeOf(AnID.mkid.cb));
      AnID := PItemIDList(Longint(AnID) + AnID.mkid.cb);
    end;
  end;

  if Size > 0 then
  begin
    Result := ShellMalloc.Alloc(Size); // Create the memory
    FillChar(Result^, Size, #0); // Initialize the memory to zero
    Move(AnID^, Result^, Size); // Copy the current ID
  end else
    Result := NIL;
end;
*)
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function BrowseDirectory(const ShellMalloc: IMalloc; var Dest: string;
   var DestPIDL: PItemIDList; var ImgIdx: integer; var DisplayName: string;
   const AParent: TWinControl; const Title: string; Root: TViewRoot;
   Flags: TBrowseTypes; WantStatusText: boolean; Callback: TFNBFFCallBack;
   Data: Longint): boolean;
var
  shBuff: PChar;
  BrowseInfo: TBrowseInfo;
  idRoot, idBrowse: PItemIDList;
  WndHandle: HWND;
begin
  Result := FALSE; // Assume the worst.
  Dest := ''; // Clear it out.
  SetLength(Dest, MAX_PATH);  // Make sure their will be enough room in dest.
  if assigned(AParent) then
    WndHandle := AParent.Handle
  else
    WndHandle := 0;
  shBuff := PChar(ShellMalloc.Alloc(MAX_PATH)); // Shell allocate buffer.
  if assigned(shBuff) then begin
    try
      // Get id for desired root item.
      SHGetSpecialFolderLocation(WndHandle, ConvertRoot(Root), idRoot);
      try
        with BrowseInfo do begin  // Fill info structure
          hwndOwner := WndHandle;
          pidlRoot := idRoot;
          pszDisplayName := shBuff;
          lpszTitle := PChar(Title);
          ulFlags := ConvertFlags(Flags);
          if WantStatusText then
            ulFlags := ulFlags or BIF_STATUSTEXT;
          lpfn := Callback;
          lParam := Data;
        end;
        idBrowse := SHBrowseForFolder(BrowseInfo);
        DestPIDL := idBrowse;
        if assigned(idBrowse) then begin
          // Try to turn it into a real path.
          if (btComputers in Flags) then
          begin
            { Make a copy because SHGetPathFromIDList will whack it }
            Dest:= '\\' + string(shBuff);
            Result := SHGetPathFromIDList(idBrowse, shBuff);
            { Is it a valid path? }
            if Result then
              Dest := shBuff // Put it in user's variable.
            else
              { do nothing, the copy we made above is set to go };
            Result:= True;
          end else begin
            Result := SHGetPathFromIDList(idBrowse, shBuff);
            Dest := shBuff; // Put it in user's variable.
          end;
          ImgIdx := BrowseInfo.iImage; // Update the image index.
        end;
        if not Result then
          Result := DestPIDL <> NIL;
        if Result then
          DisplayName := BrowseInfo.pszDisplayName;
      finally
        ShellMalloc.Free(idRoot); // Clean-up.
      end;
    finally
      ShellMalloc.Free(shBuff); // Clean-up.
    end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TFolderDlg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDisplayName := '';
  FDlgWnd := 0;
  FFitStatusText := TRUE;
  FEnableOKButton := TRUE;
  FTitle := '';
  FRoot := vrDesktop;
  FOptions := [];
  FSelection := '';
  FSelectionPIDL := NIL;
  FCenter := TRUE;
  FSelChanged := NIL;
  FStatusText := '';
  FImageIndex := -1;
  FCaption := '';
  SHGetMalloc(FShellMalloc);

  if assigned(AOwner) then
    if AOwner is TWinControl then
      FParent := TWinControl(Owner)
    else if assigned(Application) and assigned(Application.MainForm) then
      FParent := Application.MainForm;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
destructor TFolderDlg.Destroy;
begin
  if assigned(FSelectionPIDL) then
    FShellMalloc.Free(FSelectionPIDL);
  // D3 cleans it up for you, D2 does not.

  inherited Destroy;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TFolderDlg.Execute: boolean;
var
  S: string;
  AParent: TWinControl;
  TempPIDL: PItemIDList;
begin
  FDisplayName := '';
  { Assume the worst }
  AParent := NIL;
  if not (csDesigning in ComponentState) then
    { Determine who the parent is. }
    if assigned(FParent) then
      AParent := FParent
    else begin
      if assigned(Owner) then
        if Owner is TWinControl then
          AParent := TWinControl(Owner)
        else
          if assigned(Application) and assigned(Application.MainForm) then
            AParent := Application.MainForm;
    end;

  { Call the function }
  Result := BrowseDirectory(FShellMalloc, S, TempPIDL, FImageIndex,
     FDisplayName, AParent, FTitle, FRoot, FOptions,
     (FStatusText <> '') or FShowSelectionInStatus, BrowseCallbackProc,
     LongInt(Self));

  FDlgWnd := 0; { Not valid any more. }

  { If selection made, update property }
  if Result then
  begin
    FSelection := S;
    SelectionPIDL := TempPIDL;
  end else begin
    FSelection := '';
    SelectionPIDL := NIL;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function FormatSelection(const APath: string): string;
begin
  Result := APath;
  if Result <> '' then begin
    if (Length(Result) < 4) and (Result[2] = ':') then begin
      if Length(Result) = 2 then
        Result := Result + '\'
    end else
      if (Result[Length(Result)] = '\') and (Result <> '\') then
        SetLength(Result, Length(Result)-1);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SendSelectionMessage;
var
  TempSelectionPIDL: PItemIDList;
  ShellFolder: IShellFolder;
  OLEStr: array[0..MAX_PATH] of TOLEChar;
  Eaten: ULONG;
  Attr: ULONG;
  shBuff: PChar;
begin
  if (FSelection = '') and assigned(FSelectionPIDL) then
  begin
    shBuff := PChar(FShellMalloc.Alloc(MAX_PATH)); // Shell allocate buffer.
    try
      if SHGetPathFromIDList(FSelectionPIDL, shBuff) then
        FSelection := shBuff
      else
        FSelection := '';
    finally
      FShellMalloc.Free(shBuff); // Clean-up.
    end;
    SendMessage(FDlgWnd, BFFM_SETSELECTION, 0, LPARAM(FSelectionPIDL));
  end else begin
    if Copy(FSelection, 1, 2) = '\\' then // UNC name!
    begin
      if SHGetDesktopFolder(ShellFolder) = NO_ERROR then
      begin
        try
          if ShellFolder.ParseDisplayName(FDlgWnd, NIL,
             StringToWideChar(FSelection, OLEStr, MAX_PATH), Eaten,
             TempSelectionPIDL, Attr) = NO_ERROR then
          begin
            SelectionPIDL := TempSelectionPIDL;
            SendMessage(FDlgWnd, BFFM_SETSELECTION, 0, LPARAM(FSelectionPIDL));
          end;
        finally
        end;
      end;
    end else begin { normal path }
      if SHGetDesktopFolder(ShellFolder) = NO_ERROR then
      begin
        try
          if ShellFolder.ParseDisplayName(FDlgWnd, NIL,
             StringToWideChar(FSelection, OLEStr, MAX_PATH), Eaten,
             TempSelectionPIDL, Attr) = NO_ERROR then
            SelectionPIDL := TempSelectionPIDL;
        finally
        end;
        SendMessage(FDlgWnd, BFFM_SETSELECTION, 1,
           LPARAM(FormatSelection(FSelection)));
      end;
    end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.DoInitialized(Wnd: HWND);
var
  Rect: TRect;
begin
  FDlgWnd := Wnd;
  if FCenter then begin
    GetWindowRect(Wnd, Rect);
    SetWindowPos(Wnd, 0,
      (GetSystemMetrics(SM_CXSCREEN) - Rect.Right + Rect.Left) div 2,
      (GetSystemMetrics(SM_CYSCREEN) - Rect.Bottom + Rect.Top) div 2,
      0, 0, SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOZORDER);
  end;
  // Documentation for BFFM_ENABLEOK is incorrect.  Value sent in LPARAM, not WPARAM.
  SendMessage(FDlgWnd, BFFM_ENABLEOK, 0, LPARAM(FEnableOKButton));
  if FStatusText <> '' then
    SendMessage(Wnd, BFFM_SETSTATUSTEXT, 0, LPARAM(FittedStatusText));
  if (FSelection <> '') or (FSelectionPIDL <> NIL) then
    SendSelectionMessage;
  if FCaption <> '' then
    SendMessage(FDlgWnd, WM_SETTEXT, 0, LPARAM(FCaption));
  if assigned(FOnCreate) then
    FOnCreate(Self);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.DoSelChanged(Wnd: HWND; Item: PItemIDList);
var
  Name: string;
begin
  if FShowSelectionInStatus or assigned(FSelChanged) then
  begin
    Name := '';
    SetLength(Name, MAX_PATH);
    SHGetPathFromIDList(Item, PChar(Name));
    SetLength(Name, StrLen(PChar(Name)));
    if FShowSelectionInStatus then
      StatusText := Name;
    if assigned(FSelChanged) then
      FSelChanged(Self, Name, Item);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetFitStatusText(Val: boolean);
begin
  if FFitStatusText = Val then exit;
  FFitStatusText := Val;
  // Reset the status text area if needed.
  if FDlgWnd <> 0 then
    SendMessage(FDlgWnd, BFFM_SETSTATUSTEXT, 0, LPARAM(FittedStatusText));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetStatusText(const Val: string);
begin
  if FStatusText = Val then exit;
  FStatusText := Val;
  if FDlgWnd <> 0 then
    SendMessage(FDlgWnd, BFFM_SETSTATUSTEXT, 0, LPARAM(FittedStatusText));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetSelection(const Val: string);
begin
  if FSelection = Val then exit;
  FSelection := Val;
  // Add trailing backslash so it looks better in the IDE.
  if (FSelection <> '') and (FSelection[Length(FSelection)] <> '\') and
     DirExists(FSelection) then
    FSelection := FSelection + '\';
  if FDlgWnd <> 0 then
    SendSelectionMessage;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetSelectionPIDL(Value: PItemIDList);
begin
	if (FSelectionPIDL <> Value) then
  begin
    if assigned(FSelectionPIDL) then
      FShellMalloc.Free(FSelectionPIDL);
		FSelectionPIDL := Value;
	end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetEnableOKButton(Val: boolean);
begin
  if FEnableOKButton = Val then exit;
  FEnableOKButton := Val;
  if FDlgWnd <> 0 then
    // Documentation for BFFM_ENABLEOK is incorrect.  Value sent in LPARAM, not WPARAM.
    SendMessage(FDlgWnd, BFFM_ENABLEOK, 0, LPARAM(FEnableOKButton));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TFolderDlg.GetCaption: string;
var
  Temp: array[0..255] of char;
begin
  if FDlgWnd <> 0 then
  begin
    SendMessage(FDlgWnd, WM_GETTEXT, SizeOf(Temp), LPARAM(@Temp));
    Result := string(Temp);
  end else
    Result := FCaption;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetCaption(const Val: string);
begin
  FCaption := Val;
  if FDlgWnd <> 0 then
    SendMessage(FDlgWnd, WM_SETTEXT, 0, LPARAM(FCaption));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TFolderDlg.SetParent(AParent: TWinControl);
begin
  FParent := AParent;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// Note that BOOL <> boolean type.  Important!
function EnumChildWndProc(Child: HWND; Data: LParam): BOOL; stdcall;
const
  STATUS_TEXT_WINDOW_ID = 14147;
type
  PHWND = ^HWND;
begin
  if GetWindowLong(Child, GWL_ID) = STATUS_TEXT_WINDOW_ID then begin
    PHWND(Data)^ := Child;
    Result := FALSE;
  end else
    Result := TRUE;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TFolderDlg.FittedStatusText: string;
var
  ChildWnd: HWND;
begin
  Result := FStatusText;
  if FFitStatusText then begin
    ChildWnd := 0;
    if FDlgWnd <> 0 then
      // Enumerate all child windows of the dialog to find the status text window.
      EnumChildWindows(FDlgWnd, @EnumChildWndProc, LPARAM(@ChildWnd));
    if (ChildWnd <> 0) and (FStatusText <> '') then
      if DirExists(FStatusText) then
        Result := MinimizeName(ChildWnd, FStatusText)
      else
        Result := MinimizeString(ChildWnd, FStatusText);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TFolderDlg.GetDisplayName: string;
var
  ShellFolder: IShellFolder;
  Str : TStrRet;
begin
  Result := '';
  if FSelectionPIDL <> NIL then
  begin
    if SHGetDesktopFolder(ShellFolder) = NO_ERROR then
    begin
      try
        if ShellFolder.GetDisplayNameOf(FSelectionPIDL, SHGDN_FORPARSING,
           Str) = NOERROR then
        begin
          case Str.uType of
            STRRET_WSTR:   Result := WideCharToString(Str.pOleStr);
            STRRET_OFFSET: Result := PChar(Longword(FSelectionPIDL) + Str.uOffset);
            STRRET_CSTR:   Result := Str.cStr;
          end;
        end;
      finally
      end;
    end;
  end;
  if Result = '' then
    Result := FDisplayName;
  if Result = '' then
    Result := FSelection;
end;


end.
