{
This is a component for placing icons in the notification area
of the Windows taskbar (aka. the traybar).

The component is freeware. Feel free to use and improve it.
I would be pleased to hear what you think.

Troels Jakobsen - tjak@get2net.dk
}
unit CoolTrayIcon;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Menus, ShellApi, extctrls;

const
  { User-defined message sent from the icon. Some low user-defined
    messages are used by Windows itself! (WM_USER+1 = DM_SETDEFID). }
  WM_TRAYNOTIFY = WM_USER + 1024;
  IconID = 1;

type
  TCycleEvent = procedure(Sender: TObject; Current: Integer) of object;

  TCoolTrayIcon = class(TComponent)
  private
    FEnabled: Boolean;
    FIcon: TIcon;
    FIconVisible: Boolean;
    FHint: String;
    FShowHint: Boolean;
    FPopupMenu: TPopupMenu;
    FLeftPopup: Boolean;
    FOnClick,
    FOnDblClick: TNotifyEvent;
    FOnCycle: TCycleEvent;
    FOnMouseDown,
    FOnMouseUp: TMouseEvent;
    FOnMouseMove: TMouseMoveEvent;
    FStartMinimized: Boolean;
    FMinimizeToTray: Boolean;
    FClicked: Boolean;
    CycleTimer: TTimer;           // For icon cycling
    FDesignPreview: Boolean;
    SettingPreview: Boolean;
    FIconList: TImageList;
    FCycleIcons: Boolean;
    FCycleInterval: Cardinal;
    IconIndex: Integer;           // Current index in imagelist
    OldAppProc, NewAppProc: Pointer;   // Procedure variables
    procedure SetCycleIcons(Value: Boolean);
    procedure SetDesignPreview(Value: Boolean);
    procedure SetCycleInterval(Value: Cardinal);
    procedure TimerCycle(Sender: TObject);
    procedure HandleIconMessage(var Msg: TMessage);
    function InitIcon: Boolean;
    procedure SetIcon(Value: TIcon);
    procedure SetIconVisible(Value: Boolean);
    procedure SetHint(Value: String);
    procedure SetShowHint(Value: Boolean);
    procedure PopupAtCursor;
    procedure HookApp;
    procedure UnhookApp;
    procedure HookAppProc(var Message: TMessage);
  protected
    IconData: TNotifyIconData;    // Data of the tray icon wnd.
    procedure Loaded; override;
    function ShowIcon: Boolean; virtual;
    function HideIcon: Boolean; virtual;
    function ModifyIcon: Boolean; virtual;
    procedure Click; dynamic;
    procedure DblClick; dynamic;
    procedure CycleIcon; dynamic;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); dynamic;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); dynamic;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); dynamic;
    procedure DoMinimizeToTray; dynamic;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
{$IFDEF DFS_CPPB_3_UP}
    property Handle: HWND read IconData.hwnd;
{$ELSE}
    property Handle: HWND read IconData.wnd;
{$ENDIF}
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowMainForm;
    procedure HideMainForm;
    procedure Refresh;
  published
    // Properties:
    property DesignPreview: Boolean read FDesignPreview
      write SetDesignPreview default False;
    property IconList: TImageList read FIconList write FIconList;
    property CycleIcons: Boolean read FCycleIcons write SetCycleIcons
      default False;
    property CycleInterval: Cardinal read FCycleInterval
      write SetCycleInterval;
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Hint: String read FHint write SetHint;
    property ShowHint: Boolean read FShowHint write SetShowHint;
    property Icon: TIcon read FIcon write SetIcon stored True;
    property IconVisible: Boolean read FIconVisible write SetIconVisible
      default True;
    property PopupMenu: TPopupMenu read FPopupMenu write FPopupMenu;
    property LeftPopup: Boolean read FLeftPopup write FLeftPopup
      default False;
    property StartMinimized: Boolean read FStartMinimized write FStartMinimized
      default False;         // Main form minimized on appl. start-up?
    property MinimizeToTray: Boolean read FMinimizeToTray write FMinimizeToTray
      default False;         // Minimize main form to tray when minimizing?
    // Events:
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp: TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnCycle: TCycleEvent read FOnCycle write FOnCycle;
  end;

procedure Register;

implementation

{--------------------- TCoolTrayIcon ----------------------}

constructor TCoolTrayIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIconVisible := True;      // Visible by default
  FEnabled := True;          // Enabled by default
  SettingPreview := False;

  FIcon := TIcon.Create;
  IconData.cbSize := SizeOf(TNotifyIconData);
  // IconData.wnd points to procedure to receive callback messages from the icon
  IconData.wnd := AllocateHWnd(HandleIconMessage);
  // Add an id for the tray icon
  IconData.uId := IconID;
  // We want icon, message handling, and tooltips
  IconData.uFlags := NIF_ICON + NIF_MESSAGE + NIF_TIP;
  // Message to send to IconData.wnd when mouse event occurs
  IconData.uCallbackMessage := WM_TRAYNOTIFY;

  CycleTimer := TTimer.Create(Self);
  CycleTimer.Enabled := False;
  CycleTimer.Interval := FCycleInterval;
  CycleTimer.OnTimer := TimerCycle;

  // Hook into the app.'s message handling
  if not (csDesigning in ComponentState) then
    HookApp;
end;


destructor TCoolTrayIcon.Destroy;
begin
  SetIconVisible(False);     // Remove the icon from the tray
  FIcon.Free;                // Free the icon
  DeallocateHWnd(IconData.Wnd);   // Free the tray window
  CycleTimer.Free;
  // It is important to unhook any hooked processes
  if not (csDesigning in ComponentState) then
    UnhookApp;
  inherited Destroy;
end;


procedure TCoolTrayIcon.Loaded;
{ This method is called when all properties of the component have been
  initialized. The method SetIconVisible must be called here, after the
  tray icon (FIcon) has loaded itself. Otherwise, the tray icon will
  be blank (no icon image). }
begin
  inherited Loaded;	     // Always call inherited Loaded first
  if (FStartMinimized) and not (csDesigning in ComponentState) then
  begin
    Application.ShowMainForm := False;
    ShowWindow(Application.Handle, SW_HIDE);
  end;
  ModifyIcon;
  SetIconVisible(FIconVisible);
end;


procedure TCoolTrayIcon.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  { Check if either the imagelist or the popup menu
    is about to be deleted }
  if (AComponent = IconList) and (Operation = opRemove) then
    IconList := nil;
  if (AComponent = PopupMenu) and (Operation = opRemove) then
    PopupMenu := nil;
end;


{ For MinimizeToTray to work, we need to know when the form is minimized
  (happens when either the application or the main form minimizes).
  The straight-forward way is to make TCoolTrayIcon trap the
  Application.OnMinimize event. However, if you also make use of this
  event in the application, the OnMinimize code used by TCoolTrayIcon
  is discarded.
  The alternative is to hook into the app.'s message handling (via
  HookApp). You can then catch any message that goes through the app.
  and still use the OnMinimize event. }

procedure TCoolTrayIcon.HookApp;
begin
  // Hook the application
  OldAppProc := Pointer(GetWindowLong(Application.Handle, GWL_WNDPROC));
  NewAppProc := MakeObjectInstance(HookAppProc);
  SetWindowLong(Application.Handle, GWL_WNDPROC, LongInt(NewAppProc));
end;


procedure TCoolTrayIcon.UnhookApp;
begin
  if Assigned(OldAppProc) then
    SetWindowLong(Application.Handle, GWL_WNDPROC, LongInt(OldAppProc));
  if Assigned(NewAppProc) then
    FreeObjectInstance(NewAppProc);
  NewAppProc := nil;
  OldAppProc := nil;
end;


{ All app. messages pass through HookAppProc. You can override the
  messages by not passing them along to Windows (via CallWindowProc). }

procedure TCoolTrayIcon.HookAppProc(var Message: TMessage);
begin
  with Message do
  begin
    case Msg of
      WM_SIZE:
        if wParam = SIZE_MINIMIZED then
        begin
          if FMinimizeToTray then
            DoMinimizeToTray;
{ It is tempting to insert a minimize event here, but it would behave
  exactly like Application.OnMinimize, so I see no need for it. }
        end;
    end;

    Result := CallWindowProc(OldAppProc, Application.Handle, Msg, wParam, lParam);
  end;
end;


{ You can hook into the main form (or any other window) just as easily
  as hooking into the app., allowing you to handle any message that
  window processes. Uncomment the procedures HookParent and UnhookParent
  below if you want to hook the main form. Remember to unhook when the
  app. terminates, or Bad Things may happen. }
{
procedure TCoolTrayIcon.HookParent;
begin
  if Assigned(Owner as TWinControl) then
  begin
    // Hook the parent window
    OldWndProc := Pointer(GetWindowLong((Owner as TWinControl).Handle, GWL_WNDPROC));
    NewWndProc := MakeObjectInstance(HookWndProc);
    SetWindowLong((Owner as TWinControl).Handle, GWL_WNDPROC, LongInt(NewWndProc));
  end;
end;


procedure TCoolTrayIcon.UnhookParent;
begin
  if ((Owner as TWinControl) <> nil) and Assigned(OldWndProc) then
    SetWindowLong((Owner as TWinControl).Handle, GWL_WNDPROC, LongInt(OldWndProc));
  if Assigned(NewWndProc) then
    FreeObjectInstance(NewWndProc);
  NewWndProc := nil;
  OldWndProc := nil;
end;
}


{ HandleIconMessage handles messages that go to the shell notification
  window (tray icon) itself. Most messages are passed through WM_TRAYNOTIFY.
  Use lParam to get the actual message, eg. WM_MOUSEMOVE.
  Sends the usual Delphi events for the mouse messages. Also interpolates
  the OnClick event when the user clicks the left button, and makes the
  menu (if any) popup on left and right mouse down events. }

procedure TCoolTrayIcon.HandleIconMessage(var Msg: TMessage);

  function ShiftState: TShiftState;
  // Return the state of the shift, ctrl, and alt keys
  begin
    Result := [];
    if GetKeyState(VK_SHIFT) < 0 then
      Include(Result, ssShift);
    if GetKeyState(VK_CONTROL) < 0 then
      Include(Result, ssCtrl);
    if GetKeyState(VK_MENU) < 0 then
      Include(Result, ssAlt);
  end;

var
  Pt: TPoint;
  Shift: TShiftState;
  I: Integer;
  M: TMenuItem;
begin
  if Msg.Msg = WM_TRAYNOTIFY then
  // Take action if a message from the icon comes through
  begin
    case Msg.lParam of

    WM_MOUSEMOVE:
      if FEnabled then
      begin
        Shift := ShiftState;
        GetCursorPos(Pt);
        MouseMove(Shift, Pt.X, Pt.Y);
      end;

    WM_LBUTTONDOWN:
      if FEnabled then
      begin
        Shift := ShiftState + [ssLeft];
        GetCursorPos(Pt);
        MouseDown(mbLeft, Shift, Pt.X, Pt.Y);
        FClicked := True;
        if FLeftPopup then
          PopupAtCursor;
      end;

    WM_RBUTTONDOWN:
      if FEnabled then
      begin
        Shift := ShiftState + [ssRight];
        GetCursorPos(Pt);
        MouseDown(mbRight, Shift, Pt.X, Pt.Y);
        PopupAtCursor;
      end;

    WM_MBUTTONDOWN:
      if FEnabled then
      begin
        Shift := ShiftState + [ssMiddle];
        GetCursorPos(Pt);
        MouseDown(mbMiddle, Shift, Pt.X, Pt.Y);
      end;

    WM_LBUTTONUP:
      if FEnabled then
      begin
        Shift := ShiftState + [ssLeft];
        GetCursorPos(Pt);
        if FClicked then     // Then WM_LBUTTONDOWN was called before
        begin
          FClicked := False;
          Click;
        end;
        MouseUp(mbLeft, Shift, Pt.X, Pt.Y);
      end;

    WM_RBUTTONUP:
      if FEnabled then
      begin
        Shift := ShiftState + [ssRight];
        GetCursorPos(Pt);
        MouseUp(mbRight, Shift, Pt.X, Pt.Y);
      end;

    WM_MBUTTONUP:
      if FEnabled then
      begin
        Shift := ShiftState + [ssMiddle];
        GetCursorPos(Pt);
        MouseUp(mbMiddle, Shift, Pt.X, Pt.Y);
      end;

    WM_LBUTTONDBLCLK:
      if FEnabled then
      begin
        DblClick;
        { Handle default menu items. But only if LeftPopup is false,
          or it will conflict with the popupmenu, when it is called
          by a click event. }
        M := nil;
        if Assigned(FPopupMenu) then
          if (FPopupMenu.AutoPopup) and (not FLeftPopup) then
            for I := PopupMenu.Items.Count -1 downto 0 do
            begin
              if PopupMenu.Items[I].Default then
                M := PopupMenu.Items[I];
            end;
        if M <> nil then
          M.Click;
      end;
    end;
  end

  else        // Messages that didn't go through the icon
    case Msg.Msg of
      WM_QUERYENDSESSION: Msg.Result := 1;
      { Evaluate WM_QUERYENDSESSION message to tell Windows that the
        icon will stop executing if user requests a shutdown (Msg.Result
        must not return 0, or the system will not be able to shut down). }
    else      // Handle all other messages with the default handler
      Msg.Result := DefWindowProc(IconData.Wnd, Msg.Msg, Msg.wParam, Msg.lParam);
    end;
end;


procedure TCoolTrayIcon.SetIcon(Value: TIcon);
begin
  FIcon.Assign(Value);
  ModifyIcon;
end;


procedure TCoolTrayIcon.SetIconVisible(Value: Boolean);
begin
  if Value then
    ShowIcon
  else
    HideIcon;
end;


procedure TCoolTrayIcon.SetDesignPreview(Value: Boolean);
begin
  FDesignPreview := Value;
  SettingPreview := True;         // Raise flag
  SetIconVisible(Value);
  SettingPreview := False;        // Clear flag
end;


procedure TCoolTrayIcon.SetCycleIcons(Value: Boolean);
begin
  FCycleIcons := Value;
  if Value then
    IconIndex := 0;
  CycleTimer.Enabled := Value;
end;


procedure TCoolTrayIcon.SetCycleInterval(Value: Cardinal);
begin
  FCycleInterval := Value;
  CycleTimer.Interval := FCycleInterval;
end;


procedure TCoolTrayIcon.SetHint(Value: String);
begin
  FHint := Value;
  ModifyIcon;
end;


procedure TCoolTrayIcon.SetShowHint(Value: Boolean);
begin
  FShowHint := Value;
  ModifyIcon;
end;


function TCoolTrayIcon.InitIcon: Boolean;
// Set icon and tooltip
var
  ok: Boolean;
begin
  Result := False;
  ok := True;
  if (csDesigning in ComponentState) {or
     (csLoading in ComponentState)} then
  begin
    if SettingPreview then
      ok := True
    else
      ok := FDesignPreview
  end;

  if ok then
  begin
    IconData.hIcon := FIcon.Handle;
    if (FHint <> '') and (FShowHint) then
      StrLCopy(IconData.szTip, PChar(FHint), SizeOf(IconData.szTip))
      // StrLCopy must be used since szTip is only 64 bytes
    else
      IconData.szTip := '';
    Result := True;
  end;
end;


function TCoolTrayIcon.ShowIcon: Boolean;
// Add/show the icon on the tray
begin
  Result := False;
  if not SettingPreview then
    FIconVisible := True;
  begin
    if (csDesigning in ComponentState) {or
     (csLoading in ComponentState)} then
    begin
      if SettingPreview then
        if InitIcon then
          Result := Shell_NotifyIcon(NIM_ADD, @IconData);
    end
    else
    if InitIcon then
      Result := Shell_NotifyIcon(NIM_ADD, @IconData);
  end;
end;


function TCoolTrayIcon.HideIcon: Boolean;
// Remove/hide the icon from the tray
begin
  Result := False;
  if not SettingPreview then
    FIconVisible := False;
  begin
    if (csDesigning in ComponentState) {or
     (csLoading in ComponentState)} then
    begin
      if SettingPreview then
        if InitIcon then
          Result := Shell_NotifyIcon(NIM_DELETE, @IconData);
    end
    else
    if InitIcon then
      Result := Shell_NotifyIcon(NIM_DELETE, @IconData);
  end;
end;


function TCoolTrayIcon.ModifyIcon: Boolean;
// Change icon or tooltip if icon already placed
begin
  Result := False;
  if InitIcon then
    Result := Shell_NotifyIcon(NIM_MODIFY, @IconData);
end;


procedure TCoolTrayIcon.TimerCycle(Sender: TObject);
begin
  if Assigned(FIconList) then
  begin
    FIconList.GetIcon(IconIndex, FIcon);
    CycleIcon;                    // Call event method
    ModifyIcon;

    if IconIndex < FIconList.Count-1 then
      Inc(IconIndex)
    else
      IconIndex := 0;
  end;
end;

(*
procedure TCoolTrayIcon.ShowMainForm;
var
  I, J: Integer;
begin
//  Application.ProcessMessages;
  // Show application's TASKBAR icon (not the traybar icon)
  ShowWindow(Application.Handle, SW_RESTORE);
//  Application.Restore;
  // Show the form itself
  ShowWindow(Application.MainForm.Handle, SW_RESTORE);
//  Application.MainForm.BringToFront;

  { If the main form has not been shown before (if StartMinimized
    was true (Application.ShowMainForm was false on startup)),
    it's necessary to force the form's controls to show, as they
    have been created invisible (regardless of the value of their
    Visible property). This is done via ShowWindow and a lot of
    loops. }
  { By the way: TForm.Position has no effect if StartMinimized
    is true. Kind of stupid. }
{
  if not HasShown then       // This block is only executed once
  begin
    for I := 0 to Application.MainForm.ComponentCount -1 do
      if Application.MainForm.Components[I] is TWinControl then
        with Application.MainForm.Components[I] as TWinControl do
          if Visible then
          begin
            // Show this control
            ShowWindow(Handle, SW_SHOWDEFAULT);
            // Now show child controls owned by this control
            for J := 0 to ComponentCount -1 do
              if Components[J] is TWinControl then
                ShowWindow((Components[J] as TWinControl).Handle, SW_SHOWDEFAULT);
          end;
    HasShown := True;        // The main form has now been shown
  end;
}
end;
*)

procedure TCoolTrayIcon.ShowMainForm;
begin
  // Show application's TASKBAR icon (not the traybar icon)
  ShowWindow(Application.Handle, SW_RESTORE);
//  Application.Restore;
  // Show the form itself
  Application.MainForm.Visible := True;
  ShowWindow(Application.MainForm.Handle, SW_RESTORE);
end;


procedure TCoolTrayIcon.HideMainForm;
begin
  // Hide application's TASKBAR icon (not the traybar icon)
  ShowWindow(Application.Handle, SW_HIDE);
  // Hide the form itself
  ShowWindow(Application.MainForm.Handle, SW_HIDE);
end;


procedure TCoolTrayIcon.Refresh;
// Refresh the icon
begin
  ModifyIcon;
end;


procedure TCoolTrayIcon.PopupAtCursor;
var
  CursorPos: TPoint;
begin
  if Assigned(PopupMenu) then
    if PopupMenu.AutoPopup then
      if GetCursorPos(CursorPos) then
      begin
        { Win98 (but not Win95/WinNT) seems to empty a popup menu before
          closing it. This is a problem when the menu is about to display
          while it already is active (two click-events following each
          other). The menu will flicker annoyingly.
          Calling ProcessMessages fixes this. }
        Application.ProcessMessages;
        // Bring the main form to the foreground
        SetForegroundWindow(Application.MainForm.Handle);
        // Bring any modal forms owned by the main form to the foregound
        if Assigned(Screen.ActiveControl) then
          SetFocus(Screen.ActiveControl.Handle);
        // Now make the menu pop up  
        PopupMenu.PopupComponent := Self;
        PopupMenu.Popup(CursorPos.X, CursorPos.Y);
        PostMessage(Application.MainForm.Handle, WM_NULL, 0, 0);
      end;
end;


procedure TCoolTrayIcon.Click;
begin
  // Execute user-assigned method
  if Assigned(FOnClick) then
    FOnClick(Self);
end;


procedure TCoolTrayIcon.DblClick;
begin
  // Execute user-assigned method
  if Assigned(FOnDblClick) then
    FOnDblClick(Self);
end;


procedure TCoolTrayIcon.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  // Execute user-assigned method
  if Assigned(FOnMouseDown) then
    FOnMouseDown(Self, Button, Shift, X, Y);
end;


procedure TCoolTrayIcon.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  // Execute user-assigned method
  if Assigned(FOnMouseUp) then
    FOnMouseUp(Self, Button, Shift, X, Y);
end;


procedure TCoolTrayIcon.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  // Execute user-assigned method
  if Assigned(FOnMouseMove) then
    FOnMouseMove(Self, Shift, X, Y);
end;


procedure TCoolTrayIcon.CycleIcon;
begin
  // Execute user-assigned method
  if Assigned(FOnCycle) then
    FOnCycle(Self, IconIndex);
end;


procedure TCoolTrayIcon.DoMinimizeToTray;
begin
  // Override this method to change automatic tray minimizing behavior
  HideMainForm;
  IconVisible := True;
end;


procedure Register;
begin
  RegisterComponents('Custom', [TCoolTrayIcon]);
end;

end.

