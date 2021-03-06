AGSScriptModule    Steve McCrea Underwater effect Underwater 1.1 ?  // Underwater module script

__Underwater Underwater;
export Underwater;

bool gEnabled = false;

float tt = 0.0;
float t = 0.0;

float a[5], b[5], c[5];

function __Underwater::Enable()
{
  float scalar = 2000.0;
  int i = 0;
  while (i < 5)
  {
    a[i] = IntToFloat(Random(2000)*(2*Random(1)-1))/scalar;
    b[i] = IntToFloat(Random(2000)*(2*Random(1)-1))/scalar;
    c[i] = IntToFloat(Random(2000)*(2*Random(1)-1))/2000.0;
    i++;
  }
  gEnabled = true;
}

function __Underwater::Disable()
{
  gEnabled = false;
}

float get_gradient_x(int xi, int yi)
{
  float x = IntToFloat(xi)/160.0 - 1.0;
  float y = IntToFloat(yi)/160.0 - 1.0;
  
  float dx = 0.0;
  int i = 0;
  while (i < 5)
  {
    dx += a[i]*t*Maths.Cos(a[i]*t*x + b[i]*t*y + c[i]);
    i++;
  }

  return dx;
}

float get_gradient_y(int xi, int yi)
{
  float x = IntToFloat(xi)/160.0 - 1.0;
  float y = IntToFloat(yi)/160.0 - 1.0;
  
  float dy = 0.0;
  int i = 0;
  while (i < 5)
  {
    dy += b[i]*t*Maths.Cos(a[i]*t*x + b[i]*t*y + c[i]);
    i++;
  }

  return dy;
}

function offset_a_block(DrawingSurface *surf, int x, int y, int w)
{
  int xoff = FloatToInt(1.0*get_gradient_x(x + w/2, y + w/2));
  int yoff = FloatToInt(1.0*get_gradient_y(x + w/2, y + w/2));
  DynamicSprite *ds = DynamicSprite.CreateFromBackground(1, x, y, w, w);
  #ifver 3.00
  surf.DrawImage(x - xoff, y - xoff, ds.Graphic);
  #endif
  #ifnver 3.00
  RawDrawImage(x - xoff, y - yoff, ds.Graphic);
  #endif
}

function repeatedly_execute()
{
  if (gEnabled)
  {
    tt = tt + 0.01;
    t = 2.0*Maths.Pi*Maths.Sin(tt);

    SetBackgroundFrame(0);
    // repeatedly grab a random chunk from bg 1 and paste it to bg 0, slightly offset
    #ifver 3.00
    DrawingSurface *surf = Room.GetDrawingSurfaceForBackground(0);
    #endif
    int i = 0;
    while (i < 128)
    {
      i++;
      int w = Room.Width/32;
      int x = Random(Room.Width - 1 - w);
      int y = Random(Room.Height - 1 - w);

      offset_a_block(surf, x, y, w);
    }

    // draw some more around the player
    ViewFrame *frame = Game.GetViewFrame(player.View, player.Loop, player.Frame);
    int graphic = frame.Graphic;
    int height = FloatToInt(IntToFloat(Game.SpriteHeight[graphic]*player.Scaling)/100.0);
    int width  = FloatToInt(IntToFloat( Game.SpriteWidth[graphic]*player.Scaling)/100.0);
    int left = player.x - width/2;
    int top = player.y - height - player.z;

    i = 0;
    while (i < 32)
    {
      i++;
      int w = Room.Width/64;
      int x = left - w/2 + Random(width - 1);
      int y = top - w/2 + Random(height - 1);
      if (x < 0) x = 0;
      else if (x >= Room.Width - w) x = Room.Width - 1 - w;
      if (y < 0) y = 0;
      else if (y >= Room.Height - w) y = Room.Height - 1 - w;
      
      offset_a_block(surf, x, y, w);
    }
    #ifver 3.00
    surf.Release();
    #endif
  }
}
   // Underwater module header
// To use, duplicate your background in frame 1 then call Underwater.Enable from the room_Load function

struct __Underwater
{
  import function Enable();
  import function Disable();
};

import __Underwater Underwater;
 ^?u        ej??