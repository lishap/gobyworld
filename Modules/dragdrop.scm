AGSScriptModule    Ivan Mogilko Provides abstract drag-and-drop functionality DragDrop 1.0.0 ?W  
#ifdef ENABLE_MOUSE_DRAGDROP

// General settings
struct DragDropSettings
{
  bool Enabled;             // is drag'n'drop enabled
  
  eKeyCode HookKey;         // default hook key
  MouseButton HookMBtn;     // default hook mouse button
  int  DragMinDistance;     // minimal number of pixels to start drag
  int  DragMinTime;         // minimal time to start drag
  
  bool AutoTrackHookKey;    // track hook key press and release
  DragDropUnhookAction DefaultUnhookAction; // what to do by default when the hook key is up
};

DragDropSettings DDSet;

enum DragDropStep
{
  eDDIdle,          // doing nothing
  eDDWaitForObject, // waiting for an object to be selected
  eDDWaitForDrag,   // waiting for drag test to pass and drag start
  eDDDragJustStarted, // signal event: drag has just began
  eDDDragging,      // dragging an object around
  eDDDragStopped,   // hook key was released, awaiting for user decision on drop
  eDDJustDropped    // object was just placed
};

// Current drag'n'drop state
struct DragDropState
{
  int           HookKey;        // current hook key
  MouseButton   HookMBtn;       // current hook mouse button
  int           Mode;           // current drag mode
  int           Tag;            // user tag
  String        STag;           // user string tag
  
  DragDropStep  Step;           // drag'n'drop state step
  bool          ExtraTick;      // extra tick has passed in current step (workaround for overriding script modules)
  bool          ObjectJustHooked; // was the object just set up
  
  // Cursor position at which drag button was pushed down
  int           DragDownX;
  int           DragDownY;
  int           TimeDragDown; // how long the drag button was pushed down
  // Cursor position at which drag button was released
  int           DragUpX;
  int           DragUpY;
  // Starting position of the dragged object
  int           StartX;        
  int           StartY;
  // Current position of the dragged object
  int           CurrentX;
  int           CurrentY;
  // Distance between object's origin and mouse cursor; used to
  // determine where to place dragged/dropped object related to mouse cursor
  int           HandleOffsetX;
  int           HandleOffsetY;
};

DragDropState DDState;
bool          DefHookKeyWasDown;

//===========================================================================
//
// DragDropSettings::ResetToDefaults()
//
//===========================================================================
void ResetToDefaults(this DragDropSettings*)
{
  this.Enabled = false;
  this.HookKey = 0;
  this.HookMBtn = eMouseLeft;
  this.DragMinDistance = 0;
  this.DragMinTime = 0;
  this.AutoTrackHookKey = true;
  this.DefaultUnhookAction = eDDUnhookDrop;
}

//===========================================================================
//
// DragDropSettings::GetHookKeyDown()
// Gets if the default hook key is currently down.
//
//===========================================================================
bool GetHookKeyDown(this DragDropSettings*)
{
  if (this.HookKey != 0)
    return IsKeyPressed(this.HookKey);
  else if (this.HookMBtn)
    return Mouse.IsButtonDown(this.HookMBtn);
  return false;
}

//===========================================================================
//
// DragDropState::IsIdle()
//
//===========================================================================
bool IsIdle(this DragDropState*)
{
  return this.Step == eDDIdle;
}

//===========================================================================
//
// DragDropState::IsWantingObject()
//
//===========================================================================
bool IsWantingObject(this DragDropState*)
{
  return this.Step == eDDWaitForObject;
}

//===========================================================================
//
// DragDropState::IsDragging()
//
//===========================================================================
bool IsDragging(this DragDropState*)
{
  return this.Step == eDDDragging || this.Step == eDDDragJustStarted;
}

//===========================================================================
//
// DragDropState::IsDroppable()
//
//===========================================================================
bool IsDroppable(this DragDropState*)
{
  return this.Step != eDDIdle && this.Step != eDDWaitForObject;
}

//===========================================================================
//
// DragDropState::ResetState()
// Resets state description to "idle".
//
//===========================================================================
void Reset(this DragDropState*)
{
  this.HookKey = 0;
  this.HookMBtn = 0;
  this.Mode = eDragDropNone;
  this.Tag = 0;
  this.STag = null;
  this.DragDownX = 0;
  this.DragDownY = 0;
  this.TimeDragDown = 0;
  this.DragUpX = 0;
  this.DragUpY = 0;
  this.StartX = 0;
  this.StartY = 0;
  this.CurrentX = 0;
  this.CurrentY = 0;
  this.HandleOffsetX = 0;
  this.HandleOffsetY = 0;
  this.Step = eDDIdle;
  this.ExtraTick = false;
  this.ObjectJustHooked = false;
}

//===========================================================================
//
// DragDropState::OnHookKey()
//
//===========================================================================
bool OnHookKey(this DragDropState*, int user_key, MouseButton mbut)
{
  this.HookKey = user_key;
  this.HookMBtn = mbut;
  this.Step = eDDWaitForObject;
  this.ExtraTick = false;
  this.TimeDragDown = 0;
  this.DragDownX = mouse.x;
  this.DragDownY = mouse.y;
}

//===========================================================================
//
// DragDropState::SetDragObject()
//
//===========================================================================
void SetDragObject(this DragDropState*, int user_mode, int obj_x, int obj_y, int tag, String stag)
{
  this.Step = eDDWaitForDrag;
  this.ExtraTick = false;
  this.ObjectJustHooked = true;
  this.Mode = user_mode;
  this.Tag = tag;
  this.STag = stag;
  this.StartX = obj_x;
  this.StartY = obj_y;
  this.CurrentX = this.StartX;
  this.CurrentY = this.StartY;
  this.HandleOffsetX = this.DragDownX - this.CurrentX;
  this.HandleOffsetY = this.DragDownY - this.CurrentY;
}

//===========================================================================
//
// DragDropState::StartDrag()
// Starts the drag.
//
//===========================================================================
void StartDrag(this DragDropState *)
{
  this.Step = eDDDragJustStarted;
  this.ExtraTick = false;
}

//===========================================================================
//
// DragDropState::StartDropping()
// Starts the drop at current mouse cursor position.
//
//===========================================================================
void StartDropping(this DragDropState *)
{
  this.Step = eDDDragStopped;
  this.ExtraTick = false;
  this.DragUpX = mouse.x;
  this.DragUpY = mouse.y;
}

//===========================================================================
//
// GetHookKeyDown()
// Gets if the active hook key is currently down.
//
//===========================================================================
bool GetHookKeyDown(this DragDropState*)
{
  if (this.HookKey != 0)
    return IsKeyPressed(this.HookKey);
  else if (this.HookMBtn)
    return Mouse.IsButtonDown(this.HookMBtn);
  return false;
}

//===========================================================================
//
// DragDrop::HookKeyDown()
//
//===========================================================================
static void DragDrop::HookKeyDown(int user_key, MouseButton mbut)
{
  if (DDState.IsIdle())
    DDState.OnHookKey(user_key, mbut);
}

//===========================================================================
//
// DragDrop::SetDragObject()
//
//===========================================================================
static void DragDrop::HookObject(int user_mode, int obj_x, int obj_y, int tag, String stag)
{
  if (DDState.IsWantingObject())
    DDState.SetDragObject(user_mode, obj_x, obj_y, tag, stag);
}

//===========================================================================
//
// DragDrop::DragKeyUp()
//
//===========================================================================
static void DragDrop::HookKeyUp()
{
  if (DDState.IsDragging())
    DDState.StartDropping();
  else
    DDState.Reset();
}

//===========================================================================
//
// DragDrop::DropAt()
//
//===========================================================================
static void DragDrop::DropAt(int x, int y)
{
  if (!DDState.IsDroppable())
  {
    DDState.Reset();
    return;
  }

  DDState.CurrentX = x;
  DDState.CurrentY = y;  
  DDState.Step = eDDJustDropped;
  DDState.ExtraTick = false;
}

//===========================================================================
//
// DragDrop::Drop()
//
//===========================================================================
static void DragDrop::Drop()
{
  if (DDState.IsDroppable())
    DragDrop.DropAt(DDState.CurrentX, DDState.CurrentY);
  else
    DDState.Reset();
}

//===========================================================================
//
// DragDrop::Revert()
//
//===========================================================================
static void DragDrop::Revert()
{
  if (DDState.IsDroppable())
    DragDrop.DropAt(DDState.StartX, DDState.StartY);
  else
    DDState.Reset();
}

//===========================================================================
//
// DragDrop::Enabled property
//
//===========================================================================
bool get_Enabled(this DragDrop*)
{
  return DDSet.Enabled;
}

void set_Enabled(this DragDrop*, bool value)
{
  if (DDSet.Enabled && !value)
    DragDrop.Revert();
  DDSet.Enabled = value;
  if (DDSet.Enabled)
    DefHookKeyWasDown = DDSet.GetHookKeyDown();
}

//===========================================================================
//
// DragDrop::DefaultHookKey property
//
//===========================================================================
int get_DefaultHookKey(this DragDrop*)
{
  return DDSet.HookKey;
}

void set_DefaultHookKey(this DragDrop*, int value)
{
  DDSet.HookKey = value;
  DefHookKeyWasDown = DDSet.GetHookKeyDown();
}

//===========================================================================
//
// DragDrop::DefaultHookMouseButton property
//
//===========================================================================
int get_DefaultHookMouseButton(this DragDrop*)
{
  return DDSet.HookMBtn;
}

void set_DefaultHookMouseButton(this DragDrop*, int value)
{
  DDSet.HookMBtn = value;
  DefHookKeyWasDown = DDSet.GetHookKeyDown();
}

//===========================================================================
//
// DragDrop::DragMinDistance property
//
//===========================================================================
int get_DragMinDistance(this DragDrop*)
{
  return DDSet.DragMinDistance;
}

void set_DragMinDistance(this DragDrop*, int value)
{
  DDSet.DragMinDistance = value;
}

//===========================================================================
//
// DragDrop::DragMinTime property
//
//===========================================================================
int get_DragMinTime(this DragDrop*)
{
  return DDSet.DragMinTime;
}

void set_DragMinTime(this DragDrop*, int value)
{
  DDSet.DragMinTime = value;
}

//===========================================================================
//
// DragDrop::AutoTrackHookKey property
//
//===========================================================================
bool get_AutoTrackHookKey(this DragDrop*)
{
  return DDSet.AutoTrackHookKey;
}

void set_AutoTrackHookKey(this DragDrop*, bool value)
{
  DDSet.AutoTrackHookKey = value;
}

//===========================================================================
//
// DragDrop::DefaultUnhookAction property
//
//===========================================================================
int get_DefaultUnhookAction(this DragDrop*)
{
  return DDSet.AutoTrackHookKey;
}

void set_DefaultUnhookAction(this DragDrop*, int value)
{
  DDSet.AutoTrackHookKey = value;
}

//===========================================================================
//
// DragDrop::EvtWantObject property
//
//===========================================================================
bool get_EvtWantObject(this DragDrop*)
{
  return DDState.Step == eDDWaitForObject;
}

//===========================================================================
//
// DragDrop::EvtObjectHooked property
//
//===========================================================================
bool get_EvtObjectHooked(this DragDrop*)
{
  return DDState.ObjectJustHooked;
}

//===========================================================================
//
// DragDrop::EvtDragStarted property
//
//===========================================================================
bool get_EvtDragStarted(this DragDrop*)
{
  return DDState.Step == eDDDragJustStarted;
}

//===========================================================================
//
// DragDrop::EvtWantDrop property
//
//===========================================================================
bool get_EvtWantDrop(this DragDrop*)
{
  return DDState.Step == eDDDragStopped;
}

//===========================================================================
//
// DragDrop::EvtDropped property
//
//===========================================================================
bool get_EvtDropped(this DragDrop*)
{
  return DDState.Step == eDDJustDropped;
}

//===========================================================================
//
// DragDrop::IsIdle property
//
//===========================================================================
bool get_IsIdle(this DragDrop*)
{
  return DDState.IsIdle();
}

//===========================================================================
//
// DragDrop::HasObjectHooked property
//
//===========================================================================
bool get_HasObjectHooked(this DragDrop*)
{
  return DDState.IsDroppable();
}

//===========================================================================
//
// DragDrop::IsDragging property
//
//===========================================================================
bool get_IsDragging(this DragDrop*)
{
  return DDState.IsDragging();
}

//===========================================================================
//
// DragDrop::CurrentKey property
//
//===========================================================================
int get_CurrentKey(this DragDrop*)
{
  return DDState.HookKey;
}

//===========================================================================
//
// DragDrop::CurrentMouseButton property
//
//===========================================================================
MouseButton get_CurrentMouseButton(this DragDrop*)
{
  return DDState.HookMBtn;
}

//===========================================================================
//
// DragDrop::CurrentMode property
//
//===========================================================================
DragDropMode get_CurrentMode(this DragDrop*)
{
  return DDState.Mode;
}

//===========================================================================
//
// DragDrop::ObjectTag property
//
//===========================================================================
int get_ObjectTag(this DragDrop*)
{
  return DDState.Tag;
}

//===========================================================================
//
// DragDrop::ObjectSTag property
//
//===========================================================================
String get_ObjectSTag(this DragDrop*)
{
  return DDState.STag;
}

//===========================================================================
//
// DragDrop::DragStartX property
//
//===========================================================================
int get_DragStartX(this DragDrop*)
{
  return DDState.DragDownX;
}

//===========================================================================
//
// DragDrop::DragStartY property
//
//===========================================================================
int get_DragStartY(this DragDrop*)
{
  return DDState.DragDownY;
}

//===========================================================================
//
// DragDrop::ObjectStartX property
//
//===========================================================================
int get_ObjectStartX(this DragDrop*)
{
  return DDState.StartX;
}

//===========================================================================
//
// DragDrop::ObjectStartY property
//
//===========================================================================
int get_ObjectStartY(this DragDrop*)
{
  return DDState.StartY;
}

//===========================================================================
//
// DragDrop::ObjectX property
//
//===========================================================================
int get_ObjectX(this DragDrop*)
{
  return DDState.CurrentX;
}

//===========================================================================
//
// DragDrop::ObjectY property
//
//===========================================================================
int get_ObjectY(this DragDrop*)
{
  return DDState.CurrentY;
}

//===========================================================================
//
// DragDropState::Drag()
// Updates dragging move.
//
//===========================================================================
void Drag(this DragDropState *, int tick_ms)
{
  if (this.Mode == eDragDropNone)
    return; // not dragging, was called by mistake
    
  // remove "just started drag" flag
  if (this.Step != eDDDragging)
    this.Step = eDDDragging;
  this.TimeDragDown += tick_ms;
  
  this.CurrentX = mouse.x - this.HandleOffsetX;
  this.CurrentY = mouse.y - this.HandleOffsetY;
}


//===========================================================================
//
// game_start()
// Initializing DragDrop.
//
//===========================================================================
function game_start()
{
  DDSet.ResetToDefaults();
  DDState.Reset();
}

//===========================================================================
//
// repeatedly_execute_always()
// The main processing routine.
//
//===========================================================================
function repeatedly_execute_always()
{
  if (!DDSet.Enabled)
    return;

  int tick_ms = 1000 / GetGameSpeed(); // milliseconds per tick
  if (tick_ms == 0)
    tick_ms = 1; // very unlikely, but who knows...
    
  bool def_hook_key_down = DDSet.GetHookKeyDown();
  bool def_hook_key_just_pressed = def_hook_key_down && !DefHookKeyWasDown;
  DefHookKeyWasDown = def_hook_key_down;
  
  //*********************************************************************
  // Update IDLE STATE
  //*********************************************************************
  if (DDState.Step == eDDIdle)
  {
    if (DDSet.AutoTrackHookKey && def_hook_key_just_pressed)
    {
      DragDrop.HookKeyDown(DDSet.HookKey, DDSet.HookMBtn);
      // when tracking hook key, do not wait extra tick:
      // the lower scripts will be able to handle the drop this very tick in their respected "repeatedly_execute"
      DDState.ExtraTick = true;
    }
  }
  else if (DDState.Step == eDDWaitForObject)
  {
    // Object was not found, reset
    if (DDState.ExtraTick)
      DDState.Reset();
    else
      DDState.ExtraTick = true;
  }
  //*********************************************************************
  // Update DRAG TRIGGER STATE
  //*********************************************************************
  else if (DDState.Step == eDDWaitForDrag)
  {
    if (DDSet.AutoTrackHookKey && !DDState.GetHookKeyDown())
    {
      DDState.Reset();
      return;
    }
    
    if (DDState.ExtraTick)
      DDState.ObjectJustHooked = false;
    else
      DDState.ExtraTick = true;
    
    bool time_check = DDSet.DragMinTime == 0 || DDState.TimeDragDown >= DDSet.DragMinTime;
    bool move_check;
    if (DDSet.DragMinDistance > 0)
    {
      int dist_x = DDState.DragDownX - mouse.x;
      int dist_y = DDState.DragDownY - mouse.y;
      move_check = Maths.Sqrt(IntToFloat(dist_x * dist_x) + IntToFloat(dist_y * dist_y)) >= IntToFloat(DDSet.DragMinDistance);
    }
    else
    {
      move_check = true;
    }
    
    if (time_check && move_check)
      DDState.StartDrag();
    DDState.TimeDragDown += tick_ms;
  }
  //*********************************************************************
  // Update DRAGGING STATE
  //*********************************************************************
  else if (DDState.IsDragging())
  {
    DDState.ObjectJustHooked = false;
    if (!DDSet.AutoTrackHookKey || DDState.GetHookKeyDown())
      DDState.Drag(tick_ms);
    else
      DDState.StartDropping();
  }
  //*********************************************************************
  // Update DROPPING STATE
  //*********************************************************************
  else if (DDState.Step == eDDDragStopped)
  {
    if (DDSet.DefaultUnhookAction == eDDUnhookDrop)
      DragDrop.Drop();
    else
      DragDrop.Revert();
    // when dropping automatically, do not wait extra tick:
    // the lower scripts will be able to handle the drop this very tick in their respected "repeatedly_execute"
    DDState.ExtraTick = true;
  }
  //*********************************************************************
  // Update FINAL STATE
  //*********************************************************************
  else if (DDState.Step == eDDJustDropped)
  {
    if (DDState.ExtraTick)
      DDState.Reset();
    else
      DDState.ExtraTick = true;
  }
}

#endif  // ENABLE_MOUSE_DRAGDROP
 b  // DragDrop is open source under the MIT License.
//
// TERMS OF USE - DragDrop MODULE
//
// Copyright (c) 2016-present Ivan Mogilko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#ifndef __MOUSE_DRAGDROP_MODULE__
#define __MOUSE_DRAGDROP_MODULE__

#define MOUSE_DRAGDROP_VERSION_00_01_00_00

// Comment this line out to completely disable DragDrop during compilation
#define ENABLE_MOUSE_DRAGDROP

#ifdef ENABLE_MOUSE_DRAGDROP

enum DragDropMode
{
  eDragDropNone = 0
};

// An action to do when the hook key is released
enum DragDropUnhookAction
{
  eDDUnhookDrop,  // drop the dragged object at current cursor position
  eDDUnhookRevert // revert the dragged object to its initial position
};

struct DragDrop
{
  ///////////////////////////////////////////////////////////////////////////
  //
  // Setting up
  // ------------------------------------------------------------------------
  // Functions and properties meant to configure the drag'n'drop behavior.
  //
  ///////////////////////////////////////////////////////////////////////////
  
  /// Enables or disables DragDrop work, without cancelling any settings
  import static attribute bool        Enabled;
  
  /// Get/set default hook key
  import static attribute eKeyCode    DefaultHookKey;
  /// Get/set default hook mouse button
  import static attribute MouseButton DefaultHookMouseButton;
  /// Get/set minimal number of pixels the mouse should move before it is considered to be dragging
  import static attribute int         DragMinDistance;
  /// Get/set minimal time (in milliseconds) the mouse should move before it is considered to be dragging
  import static attribute int         DragMinTime;
  
  /// Get/set if the module should automatically track hook key press and release
  import static attribute bool        AutoTrackHookKey;
  /// Get/set the default action that should be done to dragged object when the hook key is released;
  /// this action may be overriden by user by explicitly calling Drop() or Revert()
  import static attribute DragDropUnhookAction DefaultUnhookAction;
  
  
  ///////////////////////////////////////////////////////////////////////////
  //
  // Event signals
  // ------------------------------------------------------------------------
  // Properties meant to signal user about drag'n'drop events.
  //
  ///////////////////////////////////////////////////////////////////////////
  
  /// Gets if the hook key was pushed down and the module is looking for the actual
  /// draggable object under the cursor; this is when the user should supply module
  /// with draggable object
  readonly import static attribute bool EvtWantObject;
  /// Gets if the draggable object was just hooked; this is when the user may take
  /// some action right before the object will be actually dragged around
  readonly import static attribute bool EvtObjectHooked;
  /// Gets if mouse drag just started; this event takes place if the draggable object
  /// was found and drag conditions were met (minimal drag time and/or distance)
  readonly import static attribute bool EvtDragStarted;
  /// Gets if the mouse drag was just released; the event takes place just a tick
  /// before object is actually dropped on a new place, letting user to choose a drop
  /// coordinates or revert the drag
  readonly import static attribute bool EvtWantDrop;
  /// Gets if the object was just dropped on a new position
  readonly import static attribute bool EvtDropped;
  
  
  ///////////////////////////////////////////////////////////////////////////
  //
  // State control
  // ------------------------------------------------------------------------
  // Properties and functions meant to tell about current drag'n'drop process
  // and control its state.
  //
  ///////////////////////////////////////////////////////////////////////////
  
  /// Gets if the module is currently doing nothing
  readonly import static attribute bool         IsIdle;
  /// Gets if the module has an object hooked (during pre-dragging, dragging or dropping states)
  readonly import static attribute bool         HasObjectHooked;
  /// Gets if the mouse is currently being dragged (drag button held down and mouse moved)
  readonly import static attribute bool         IsDragging;
  /// Gets the current hook key
  readonly import static attribute int          CurrentKey;
  /// Gets the current drag mouse button
  readonly import static attribute MouseButton  CurrentMouseButton;
  /// Gets the current drag mode (this hints the type of object being dragged)
  readonly import static attribute int          CurrentMode;
  /// Gets the user-defined dragged object integer tag
  readonly import static attribute int          ObjectTag;
  /// Gets the user-defined dragged object String tag
  readonly import static attribute String       ObjectSTag;
  /// Gets X coordinate of cursor position at which the hook key was pushed down
  readonly import static attribute int          DragStartX;
  /// Gets Y coordinate of cursor position at which the hook key was pushed down
  readonly import static attribute int          DragStartY;
  /// Gets X coordinate of initial object's position
  readonly import static attribute int          ObjectStartX;
  /// Gets Y coordinate of initial object's position
  readonly import static attribute int          ObjectStartY;
  /// Gets X coordinate of the dragged object's position
  readonly import static attribute int          ObjectX;
  /// Gets Y coordinate of the dragged object's position
  readonly import static attribute int          ObjectY;
  
  /// Notify hook key push down; this does not have to be real keycode
  import static void  HookKeyDown(int user_key = 0, MouseButton mbtn = 0);
  /// Assign a draggable object for the module when it expects to find one under the mouse cursor
  import static void  HookObject(int user_mode, int obj_x, int obj_y, int tag = 0, String stag = 0);
  /// Notify hook key release
  import static void  HookKeyUp();
  
  /// Drop the object now
  import static void  Drop();
  /// Drop the object now and position it at the given coordinates
  import static void  DropAt(int x, int y);
  /// Reset drag; if an AGS object was dragged, return it to original position
  import static void  Revert();
};

#endif  // ENABLE_MOUSE_DRAGDROP

#endif  // __MOUSE_DRAGDROP_MODULE__
 %4l        ej??