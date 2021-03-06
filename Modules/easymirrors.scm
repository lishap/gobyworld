AGSScriptModule        <?  #define MAX_MIRRORS 50 //no more than MAX_MIRRORS individual mirrors in the entire game
#define MAX_MIRRORS_PER_ROOM 10




struct MirrorData
{
  
  bool enabled;

  int symmetryType;
  
  Object* mask;
  Object* center;
  int room;
  int angle;
  int inclination;
  float opacity; //0.0 to 1.0. 
  float distance_attenuation;
  int width;
  int height;
  int x;
  int y;
  int x_offset;
  int y_offset;
  int x_center;
  int y_center;
  Region* reg;
  
  Character* c;
  Character* substitute; //if null, then don't use a substitute
};


MirrorData data[MAX_MIRRORS];
int nbMirrors = 0;

Character* mirrorChars[MAX_MIRRORS_PER_ROOM]; //the characters that we use as mirror reflections
int nbMirrorsChars = 0;

//int unpackedView; //the character view currently unpacked into 'unpacked[]'.

static void Mirrors2::AddMirrorChar(Character* c)
{
  if (nbMirrorsChars>=MAX_MIRRORS_PER_ROOM-1) 
      AbortGame("ERROR: Mirrors::AddMirrorChar : too many mirrors in this room. Increase MAX_MIRRORS_PER_ROOM");
  
  int i=0;
  while (i<nbMirrorsChars) {
    if (mirrorChars[i] == c)
      AbortGame(String.Format("ERROR: Mirrors::AddMirrorChar : you already used %s as a mirror reflection!", c.Name));
    i++;
  }
  
  int newMirrorChar = nbMirrorsChars;
  nbMirrorsChars++;
  
  
  mirrorChars[newMirrorChar] = c;
  
}

//finds a "mirror character" (those characters we use for the reflections)
//that is NOT used by any mirror in room "room".
//otherwise returns -1
int findUnusedMirrorChar(int room)
{
  int found = -1;
  
  int i=0;
  while (i<nbMirrorsChars) { //we iterate through all the "mirror characters"
    found = i;
    
    int m=0;
    while (m<nbMirrors) { //then we try out every mirror
      if (data[m].room == room) { //is it used in this room?
        if (data[m].c == mirrorChars[i]) { // if yes, does that mirror use that mirror character?
          found = -1; //bad luck. We'll iterate and try with another mirror char
          m = nbMirrors; //we force the exit of the loop
        }
      }
      m++;
    }
    if (found != -1) //none of the mirrors in this room uses that "mirror character"
      return found;
      
    i++;
  }
}


//////////////////////////////////////////////////
//
//        REST OF LOGIC
//
//////////////////////////////////////////////////



struct ObjectData {
  int top;
  int left;
  int x_center;
  int y_center;
  int width;
  int height;
};
ObjectData objData;


//The only decent way to get some data about an object is to study its graphic sprite.
//The result is stored in ObjectData until the next call to GetObjectData.
void GetObjectData(Object* obj) {
  DynamicSprite* spr = DynamicSprite.CreateFromExistingSprite(obj.Graphic);
  
  objData.width= spr.Width;
  objData.height= spr.Height; 

  objData.top = obj.Y-spr.Height; //SURPRISE, MOTHERFUCKER
  objData.left = obj.X;
  
  objData.x_center = objData.left+objData.width/2;
  objData.y_center = objData.top+objData.height/2;
  
  spr.Delete();
}



int findMirror(Object* mask) 
{
  int i=0;
  while (i<MAX_MIRRORS) {
    if (data[i].mask == mask)
      return i;
    i++;
  }
  
  return -1;
}


static void Mirrors2::NewMirror( Object* mask,  //set to null if no mask
                                Object* center, 
                                Region* reg,   //set to null if mirror always on
                                Mirrors_Symmetries symmetry,  
                                float opacity,  
                                float distance_attenuation,  
                                int x_offset,  
                                int y_offset)
{
  if (nbMirrors>=MAX_MIRRORS-1) 
      AbortGame("ERROR: Mirrors::NewMirror : too many mirrors in your game. Increase MAX_MIRRORS");
  
  //check if this mirror has already been declared (its mask is already used)
  if (findMirror(mask)>= 0)
    AbortGame("ERROR: Mirrors::NewMirror : Bad scripting! you've declared the same mirror twice");

  
  int newMirror = nbMirrors;
  nbMirrors++;
  
  
  data[newMirror].room = player.Room;
  data[newMirror].mask = mask;
  data[newMirror].mask.Baseline = 2; //baseline 0 = background, baseline 1 = reflection, baseline 2 = mask 
  data[newMirror].center = center; //we only want that object for x_center and y_center
    center.Visible = false; //We make it invisible
    center.Baseline=0;  
  data[newMirror].x_offset = x_offset;
  data[newMirror].y_offset = y_offset;
  data[newMirror].symmetryType = symmetry;
  data[newMirror].reg = reg;
  data[newMirror].distance_attenuation = distance_attenuation;
  
  GetObjectData(center);
  data[newMirror].x_center = objData.x_center;
  data[newMirror].y_center = objData.y_center;

  if (opacity<0.0 || opacity > 1.0)
    AbortGame(String.Format("NewMirror: Incorrect opacity value: %f. Must be 0.0 to 1.0", opacity));
  data[newMirror].opacity = opacity;

  //we get some data from the mirror object
  GetObjectData(mask);
  data[newMirror].width = objData.width;
  data[newMirror].height = objData.height;
  data[newMirror].x = objData.left;
  data[newMirror].y = objData.top;

  //let's find a character that this mirror will use for its reflection
  int m = findUnusedMirrorChar(player.Room);
  if (m == -1)
    AbortGame("NewMirror: Could not find an unused mirror character. You must call 'AddMirrorChar' once more!");
  data[newMirror].c = mirrorChars[m];

  data[newMirror].substitute = null;
  
  
  //disable the mirror (will have to be enabled manually by the end-scripter)
  data[newMirror].enabled = false;
  
}

  //To modify the offset you've set in NewMirror
static void Mirrors2::SetOffset(Object* mask, int x_offset,  int y_offset)
{
  int m = findMirror(mask) ;
  if (m<0)
    AbortGame("Mirrors::SetOffset : could not find mirror. Did you call NewMirror first?");

   data[m].x_offset = x_offset;
   data[m].y_offset = y_offset;
   
}

  
  //To modify the opacity you've set in NewMirror
static void Mirrors2::SetOpacity(Object* mask, float opacity)
{
  int m = findMirror(mask) ;
  if (m<0)
    AbortGame("Mirrors::SetOpacity : could not find mirror. Did you call NewMirror first?");

   data[m].opacity = opacity;


} 
  
static void Mirrors2::SetSubstituteCharacter(Object* mask,  Character* c)
{
  int m = findMirror(mask);
  if (m<0)
    AbortGame("Bad scripting in 'SetSubstituteCharacter': that mirror has not been previously created. Call NewMirror first!");
  
  if (data[m].substitute!=null) //there's alreayd a substitute.
    data[m].substitute.ChangeRoom(0, 160, 100); //let's send it to the dump room
    
  data[m].substitute = c;
  data[m].c = null; //that mirror won't be needing a reflection anymore
  
}


static void Mirrors2::DisableAllMirrors()
{
  int i=0;
  while (i<nbMirrors)
  {
    data[i].enabled = false;
    i++;
  }  
}


static void Mirrors2::EnableAllMirrorsInRoom()
{
  int i=0;
  while (i<nbMirrors)
  {
    if (data[i].room == player.Room)
      data[i].enabled = true;
    i++;
  }
}
  
  

//returns true if there are no mirrors in the room where the player is
bool NoMirrorsInThisRoom()
{
    int i=0;
    while (i<nbMirrors) { //We render every mirror 
       if (data[i].room == player.Room) //we render ti only if it's enabled
         return false;
       i++;
    }
    return true;
}


static void Mirrors2::EnableMirror (Object* mirror)
{
  int m = findMirror(mirror) ;
  if (m>=0)
    data[m].enabled = true;
  else
    AbortGame("Mirrors::EnableMirror : you tried to enable a mirror that wasn't registered before using NewMirror");
}




//AGS doesn't give that information. You have to reverse-calculate it :/
struct CharData
{
  int left;
  int top;
};

CharData charData;


//returns the "mirrored" loop to any loop, based on the symmetry type.
//e.g. if you give it the loop for "down", depending on the symmetry type
//this function can return the loop for "up".
function mirrorLoop(int loop,  int symetryType)
{
    if ( symetryType == eSymmetryHoriz) //the bottom of a square mirror would appear as a horizontal line on the screen (i.e. the mirror faces the viewer)
    {
      if (loop == eLoopUp) //if the player sees the back of the character...
        return eLoopDown; //...then in the mirror he'll see his front
      else if (loop == eLoopDown) //if the player sees the front of the character...
        return eLoopUp; //...then in the mirror he'll see his back
      else
        return loop; //leave as-is
    }
    else if(symetryType == eSymmetryVertic)  //the bottom of a square mirror would appear as a vertical line on the screen (i.e. the mirror is oriented 90? from the viewpoint the viewer)
    {
      if (loop == eLoopLeft) //if the character is facing left...
        return eLoopRight; //...then in the mirror he appears as facing right
      else if (loop == eLoopRight) //if the character is facing right...
        return eLoopLeft; //...then in the mirror he appears as facing left
      else
        return loop; //leave as-is
    }
    else if(symetryType == eSymmetryUpDown)  //like in a lake
    {
      //nothing to do
    }
    else if(symetryType == eSymmetryNone)  //no symmetry at all. As-is
    {
      //nothing to do
    }
    else
    {
        AbortGame(String.Format("Mirrors::mirrorLoop : unexpected symetry type %d",symetryType) );
        
    }  
    return loop; //safety
}


//////////////////
// utility functions
///////////////////

float min_float(float value1,  float value2) { if (value1<value2) return value1; return value2; }
float max_float(float value1,  float value2) {  if (value1>value2) return value1; return value2; }

int min(int value1,  int value2) {   if (value1<value2) return value1;  return value2; }
int max(int value1,  int value2) {   if (value1>value2) return value1;  return value2; }

int abs(int value) { if (value <0) return -value; return value; }


//////////////////
// end of utility functions
///////////////////




void AssertSymmetryType(int mir_index) 
{
  bool horiz = data[mir_index].symmetryType & eSymmetryHoriz; //binary comparison (in case there are several symmetries at once)
  bool vertic = data[mir_index].symmetryType & eSymmetryVertic;
  bool updown = data[mir_index].symmetryType & eSymmetryUpDown;
  bool none = data[mir_index].symmetryType & eSymmetryNone;
  
  if (!(horiz || vertic || updown || none)) //no symmetry type!
    AbortGame(String.Format("Mirrors::AssertSymmetryType : Unexpected symmetry type %d", data[mir_index].symmetryType));
    
  if (data[mir_index].symmetryType > eSymmetryNone) //more than one symmetry type at once
    AbortGame(String.Format("Mirrors::AssertSymmetryType : Composite symmetry types not implemented: %d", data[mir_index].symmetryType));
}


float CalculateOpacity(int mir_index,  int distanceToMirror_x,  int distanceToMirror_y) {
  
  float alpha = 0.5; //safety
  float ALPHA_ATTENUATE  = data[mir_index].distance_attenuation;
   
  if ( data[mir_index].symmetryType == eSymmetryHoriz) //the bottom of a square mirror would appear as a horizontal line on the screen (i.e. the mirror faces the viewer)
    alpha = 1.0 - max_float(min_float(IntToFloat(abs(distanceToMirror_y)),  ALPHA_ATTENUATE),  0.0)/ALPHA_ATTENUATE;
  if(data[mir_index].symmetryType == eSymmetryVertic)  //the bottom of a square mirror would appear as a vertical line on the screen (i.e. the mirror is oriented 90? from the viewpoint the viewer)
    alpha = 1.0 - max_float(min_float(IntToFloat(abs(distanceToMirror_x)),  ALPHA_ATTENUATE),  0.0)/ALPHA_ATTENUATE;
  if(data[mir_index].symmetryType == eSymmetryUpDown)  //like in a lake
    alpha = 1.0;  
  if(data[mir_index].symmetryType == eSymmetryNone)  //no symmetry
    alpha = 1.0;  
    
  alpha = alpha*data[mir_index].opacity; //the global opacity is also affected by the mirror's global opacity setting
  
  return alpha;
}

int GetPerspectiveCorrection_x(int mir_index)
{             
  if ( data[mir_index].symmetryType == eSymmetryHoriz) //the bottom of a square mirror would appear as a horizontal line on the screen (i.e. the mirror faces the viewer)
    return 0;
  else if(data[mir_index].symmetryType == eSymmetryVertic)  //the bottom of a square mirror would appear as a vertical line on the screen (i.e. the mirror is oriented 90? from the viewpoint the viewer)
    return player.x - data[mir_index].x_center; //if the player moves away from the mirror, his reflection also moves away "inside" the mirror.
  else if(data[mir_index].symmetryType == eSymmetryUpDown)  //like in a lake
    return 0;
  else if (data[mir_index].symmetryType == eSymmetryNone)  //no symmetry. As-is
    return 0;
}

int GetPerspectiveCorrection_y(int mir_index)
{         
  if ( data[mir_index].symmetryType == eSymmetryHoriz) //the bottom of a square mirror would appear as a horizontal line on the screen (i.e. the mirror faces the viewer)
    return player.y - data[mir_index].y_center; //if the player moves away from the mirror, his reflection also moves away "inside" the mirror.
  else if(data[mir_index].symmetryType == eSymmetryVertic)  //the bottom of a square mirror would appear as a vertical line on the screen (i.e. the mirror is oriented 90? from the viewpoint the viewer)
    return 0;
  else if(data[mir_index].symmetryType == eSymmetryUpDown)  //like in a lake
    return data[mir_index].y_center-player.y;
  else if (data[mir_index].symmetryType == eSymmetryNone)  //no symmetry. As-is
    return 0;
}

function RenderMirror(int mir_index)
{
  AssertSymmetryType(mir_index) ; //crashes the game if the symmetry type is not correct

  int x = data[mir_index].x; //top of the mirror (on screen)
  int y = data[mir_index].y; //left of the mirror (on screen)

  int perspective_x=GetPerspectiveCorrection_x(mir_index);
  int perspective_y=GetPerspectiveCorrection_y(mir_index);

  float transparency = 1.0 - CalculateOpacity(mir_index, perspective_x, perspective_y); 
  

  Character* c; //the reflection will be...
  if (data[mir_index].c != null) { //...the mirror's own. It looks exactly like the player
    c = data[mir_index].c;
    c.ChangeView(player.View);
  }
  else if (data[mir_index].substitute != null){ //..our very own substitute
    c = data[mir_index].substitute;
  }

  if (c.Room != player.Room)
    c.ChangeRoom(player.Room, 160, 100); //we bring it in
  
  c.x= player.x - 2*perspective_x +  data[mir_index].x_offset;
  c.y= player.y - 2*perspective_y +  data[mir_index].y_offset;

  
  
  c.Frame = player.Frame;
  c.Loop = mirrorLoop(player.Loop,  data[mir_index].symmetryType);
  
  c.Transparency = FloatToInt(transparency*100.0);
  //c.Baseline = player.y - 1; //the reflection is always BEHIND the player
  c.Baseline = 1; //the reflection is always BEHIND the player and BEHING the mask  (don't use 0, it's a special value)

 
   LabelDebug.Text = String.Format("transp=%d", c.Transparency);
}  


function repeatedly_execute_always()
{
  if (!IsGamePaused())
  {      
      
      int i=0;
      while (i<nbMirrors) //We render every mirror 
      {
         if (     data[i].room == player.Room //if the mirror is in the current room
              &&  data[i].enabled == true) //we render it only if it's enabled
         {
            if (Region.GetAtRoomXY(player.x,  player.y) == data[i].reg) //if the player is standing on the trigger region
              RenderMirror(i);
            else {
              if (data[i].c != null)
                data[i].c.Transparency = 100;
              if (data[i].substitute != null)
                data[i].substitute.Transparency = 100;
            }
         }
         
         i++;
      }

  }
}

  
void game_start()
{
  //do this only once in your entire game
  Mirrors2.AddMirrorChar(cMirror1);
  Mirrors2.AddMirrorChar(cMirror2);
  Mirrors2.AddMirrorChar(cMirror3);


}
 ?  //#define MIRROR int


//note that those can be combined, binary-style
enum Mirrors_Symmetries{
  eSymmetryHoriz = 1, //the mirror is a plane facing the gamer
  eSymmetryVertic = 2,  //the mirror is turned 90? from the gamer's viewpoint
  eSymmetryUpDown = 4, 
  eSymmetryNone = 8 //this leaves the sprite as-is but uses the "substitute character" (useful for upside-down mirrors)
};


//hard-coded utility values, to map the views' standard loops
enum Mirrors_LoopsIndices {
  eLoopDown = 0, 
  eLoopLeft = 1, 
  eLoopRight = 2, 
  eLoopUp = 3
};


struct Mirrors2
{
 
  //tells the module that character "c" can be used as a mirror reflection.
  //Call this function at least once (i.e. give the module at least one character)
  //otherwise it can't work!
  //You should call this function as many times as there are mirrors in the room
  // that has the most mirrors.
  //For example if there are two mirrors in a room, and if that is the room
  //of your game that has the most mirrors, then call this function twice.
  //(with two different characters!).
  import static void AddMirrorChar(Character* c); 
  
  //Declares a new mirror in the current room. The player MUST be in that room when NewMirror is called!
  // This must be done only ONCE in the entire game (in "first time enters room")
  // The mirror starts disabled. It has to be enabled (using script) afterwards to be visible.
  //
  // 'mirror' is the object containing the sprite used as the mask.
  // 'center' is a marker. The center of its sprite (width/2, height/2) should be where the player would stand (his feet coordinates) if he was glued to the mirror ;)
  // 'symetry' is one of the symetries in the enum above
  // 'x_offset' and 'y_offset' allow to shit the reflection by a constant number of pixels
  // 'opacity' must be in 0.0, 1.0. Note: if the mirror's opcaity is 1.0 then it's fully opaque, therefore there's NO reflection!
  // 'distance_attenuation' (recommended value '60.0'): if the player stands 0 pixels away from the mirror, his reflection will appear fully opaque. If he's standing 'distance_attenuation' pixels away from the mirror (or more), his reflection will be fully transparent
  import static void NewMirror( Object* mask,  //set to null if no mask
                                Object* center, 
                                Region* reg,   //set to null if mirror always on
                                Mirrors_Symmetries symmetry,  
                                float opacity,  
                                float distance_attenuation,  
                                int x_offset=0,  
                                int y_offset=0);

  //Tells the module that this mirror should use an entirely
  //different character altogether as the reflection, instead of computing 
  //the reflection.
  //That character should use Views that have the same number of loops and frames
  //as the player character.
  import static void SetSubstituteCharacter(Object* mask,  Character* c);
  
  //To modify the offset you've set in NewMirror
  import static void SetOffset(Object* mask, int x_offset,  int y_offset);
  
  //To modify the opacity you've set in NewMirror
  import static void SetOpacity(Object* mask, float opacity);
  
  //That doesn't delete the mirrors in memory (which is done automaticaly). It just disables them so that they're not rendered
  import static void DisableAllMirrors();
  
  //Enables all mirrors in THIS room if they've been previously declared with 'NewMirror'
  import static void EnableAllMirrorsInRoom();
  
  //Enables one mirror selectively
  import static void EnableMirror (Object* mirror);
  
  
  
}; ?X        ej??