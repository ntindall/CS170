
// value of clock
8000::samp => dur T;

// dimensions
14 => int height;
14 => int width;

20000 => int attackMs;
0  => int decayMs;
1  => float sustainGain;
10000 => int releaseMs;

/********************************************************************* Scales */
11 => int HIRAJOSHI;
int hirajoshi[width];

19 => int PENTATONIC;
int pentatonic[width];

4 => int AMINOR; //sus2
int aminor[width];

7 => int DMINOR;
int dminor[width];

fun void initscales()
{
  60 => int C;
  61 => int Db;
  62 => int D; 
  63 => int Eb;
  64 => int E;
  65 => int F; 
  66 => int Gb; 
  67 => int G; 
  68 => int Ab;
  69 => int A;
  70 => int Bb;
  71 => int B;

  [C-24, E-24, Gb-24, G-24, B-24, C-12, E-12, Gb-12, G-12, 
         E-12, C-12, B-24, G-24, E-24] @=> hirajoshi;

  [C-24, D-24, E-24, G-24, A-24, C-12, D-12, E-12, G-12, 
         E-12, D-12, C-24, G-24, D-24] @=> pentatonic;

  [A-36, C-24, E-24, A-24, C-24, D-12, E-12, A-12, E-12, 
         C-12, B-12, A-24, D-24, C-24] @=> aminor;

  [D-36, A-36, C-24, D-24, F-24, A-12, D-12, A-12, F-12, 
         D-12, A-24, F-24, E-24, D-24] @=> dminor;

}

/************************************************* Global Grid Initialization */

// -------------
// graphics init
// -------------
// send objects
OscSend graphicsXmit;
// port
4242 => int graphicsPort;

// aim the transmitter at port
graphicsXmit.setHost ( "localhost", graphicsPort ); 

// -------------

//zero initialized, heap memory
new GridCell[height*width] @=> GridCell @ grid[];

//The location of each target
PlayerState positions[16];

class PlayerState {
    int x;
    int y;

    HSV color;
}

/***************************************************** Network Initialization */

// send objects
OscSend xmit[16];
// number of targets (initialized by netinit)
int targets;
// port
6449 => int port;

// create our OSC receiver
OscRecv recv;
// use port 6449
6451 => recv.port;
// start listening (launch thread)
recv.listen();


// aim the transmitter at port
fun void netinit() {
  if (me.arg(0) == "local" || me.arg(0) == "l" || me.arg(0) == "localhost")
  {
    1 => targets;
    xmit[0].setHost ( "localhost", port );
  } else 
  {
    //NOTE: REMEMBER TO MODIFY TARGET VALUE OR WILL AOOBE
    1 => targets;
    xmit[0].setHost ( "localhost", port );
   // xmit[1].setHost ( "Nathan.local", port );
    /*
    xmit[2].setHost ( "tikkamasala.local", port );
    xmit[3].setHost ( "transfat.local", port );
    xmit[4].setHost ( "peanutbutter.local", port );
    xmit[5].setHost ( "tofurkey.local", port );
    xmit[6].setHost ( "doubledouble.local", port );
    xmit[7].setHost ( "seventeen.local", port );
    xmit[8].setHost ( "aguachile.local", port );
    xmit[9].setHost ( "snickers.local", port );
    xmit[10].setHost ( "padthai.local", port );
    xmit[11].setHost ( "flavorblasted.local", port );
    xmit[12].setHost ( "dolsotbibimbop.local", port );
    xmit[13].setHost ( "poutine.local", port );
    xmit[14].setHost ( "shabushabu.local", port );
    xmit[15].setHost ( "froyo.local", port );
    */
    //xmit[11].setHost ( "pupuplatter.local", port );
    //xmit[13].setHost ( "xiaolongbao.local", port );
    //xmit[14].setHost ( "turkducken.local", port );
    //xmit[16].setHost ( "oatmealraisin.local", port );
  }
}

/*********************************************************** Driver Functions */

fun void printGridCell(GridCell @ var) 
{
  <<< "p:", var.pitch, " o: ", var.isOccupied() >>>;
}

fun void printPlayerState(int id, PlayerState @ pos) 
{
    <<< "ID: ", id, " at x: ", pos.x, " y: ", pos.y, pos.color.toString() >>>;
}

fun void gridinit(int which)
{

  int scale[];

  if (which == HIRAJOSHI) 
  {
    hirajoshi @=> scale;
    <<< "Scale: HIRAJOSHI" >>>;
  }

  if (which == PENTATONIC)
  {
    pentatonic @=> scale;
    <<< "Scale: PENTATONIC" >>>;
  } 

  if (which == AMINOR)
  {
    aminor @=> scale;
    <<< "Scale: AMINOR" >>>;
  }

  if (which == DMINOR)
  {
    dminor @=> scale;
    <<< "Scale: DMINOR" >>>;
  }

  for( 0 => int y; y < height; y++ ) 
  {
    for( 0 => int x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;
      if (y > height / 2)
      {
        scale[x] + (height - y) * 12 => grid[idx].pitch;
      } 
      else 
      {
        scale[x] + y * 12 => grid[idx].pitch;
      }
    }
  }
}

fun void targetinit()
{
  for (int i; i < targets; i++)
  {
    // Math.random2(0,width - 1) => positions[i].x;
    // Math.random2(0,height - 1) => positions[i].y;
    0 => positions[i].x;
    0 => positions[i].y;
  }
}

fun string printGrid(int targetIdx) {

  "----------------------------\n" => string result;
  for( height - 1 => int y; y >= 0; y--) 
  {
    for( 0 => int x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;

      if (grid[idx].isOccupied()) 
      {
        if (targetIdx == idx) 
        {
          //todo, be smarter about commandline feedback to give clients
          //information about state
          "X  " +=> result;

        } else {
          "1  " +=> result;
        }
      } else {
        "0  " +=> result;
      }
    }
    "\n" +=> result;
  }

  return result;
}

fun void updateClient(int z)
{
  positions[z] @=> PlayerState curPlayer; 
  printPlayerState(z, curPlayer);

  // start the message...
  //id midi h s v grid a d s r
  xmit[z].startMsg( "/slork/synch/synth", "i i i i i s i i f i" );

  // a message is kicked as soon as it is complete 
  // - type string is satisfied and bundles are closed
  z                                   => xmit[z].addInt;
  grid[curPlayer.y*width+curPlayer.x].pitch => xmit[z].addInt;
  curPlayer.color.h                            => xmit[z].addInt;
  curPlayer.color.s                            => xmit[z].addInt;
  curPlayer.color.v                            => xmit[z].addInt;

  printGrid(curPlayer.y*width+curPlayer.x) => xmit[z].addString;

  attackMs  => xmit[z].addInt;
  decayMs   => xmit[z].addInt;
  sustainGain    => xmit[z].addFloat;
  releaseMs => xmit[z].addInt; 

}

fun void updateClients()
{
  for( 0 => int z; z < targets; z++ ) 
  {
    updateClient(z); //no need to spork
  }
}

fun void sendClock() {

  while (true)
  {
    for (int z; z < targets; z++)
    {
      // a message is kicked as soon as it is complete 
      xmit[z].startMsg( "/slork/synch/clock");
    }

    //clock speed tunable by T
    T => now;
  }

}

fun void handleClient()
{
  // create an address in the receiver, store in new variable
  //id x y
  recv.event( "/slork/synch/move, i i i" ) @=> OscEvent oe;

  while ( true )
  {
    oe => now;

    while ( oe.nextMsg() != 0 )
    {
      oe.getInt() => int id;
      oe.getInt() => int dY;
      oe.getInt() => int dX;

      //unset occupied for old position
      0 => grid[positions[id].y*width+positions[id].x].who[id];

      //get x
      positions[id].x + dX => positions[id].x;

      //x bounds
      if (positions[id].x > width - 1) 0 => positions[id].x;
      if (positions[id].x < 0) width - 1 => positions[id].x;

      //get y
      positions[id].y + dY => positions[id].y;

      //y bounds
      if (positions[id].y > height - 1) 0 => positions[id].y;
      if (positions[id].y < 0) height - 1 => positions[id].y;

      1 => grid[positions[id].y*width+positions[id].x].who[id];

      spork ~g_updatePlayerPos(id, positions[id].x, positions[id].y);
      spork ~updateClients();
    }
  }
}

fun void handleAction() {
  //create an address to store action events
  //id actionID
  recv.event( "/slork/synch/action, i i") @=> OscEvent acte;

  while (true)
  {
    acte => now;

    while ( acte.nextMsg() != 0)
    {
      acte.getInt() => int id;
      acte.getInt() => int actionId;

      //if only there were enums
      if (actionId == ActionEnum.jump())
      {
        //update graphics
        <<< "Jump received!!! from ", id >>>;
      }

      if (actionId == ActionEnum.tinkle())
      {
        //update graphics
        <<< "Tinkle received!!! from ", id >>>;
      }
    }
  }

}

fun void g_updatePlayerPos(int id, int x, int y) {
  graphicsXmit.startMsg("/nameless/graphics/position", "i i i");
  id => graphicsXmit.addInt;
  x => graphicsXmit.addInt;
  y => graphicsXmit.addInt;
}

fun void slewIdxColor(int z, int hue)
{
  positions[z].color @=> HSV color;
  hue - color.h       => int hueDelta;

  //complicated math
  if (Math.abs(hueDelta) >= 180) 
  {
    if (hueDelta < 0)
    {
      (hueDelta + 360) => hueDelta;
    } else if (hueDelta > 0)
    {
    -(360 - hueDelta) => hueDelta;
    }
  }

  20                  => int numSteps;

  (hueDelta $ float )/ numSteps   => float stepSize;

  //keep accurate sum in sum, but cast down to appropriate hue 
  color.h $ float                 => float sum;

  for (int i; i < numSteps; i++)
  {
    sum + stepSize => sum;
    if (sum >= 360) 0 => sum;
    if (sum < 0) 359 => sum;

    //in case step size is small, just end.
    if (sum $ int == color.h) break;

    //cast down
    sum $ int => color.h; 

    //let everyone know some slewing has occured!
    spork ~updateClient(z);
    //update graphics

    //expected time to completion is 10 seconds
    Math.random2(1,1000)::ms => now;
  }

  //make sure we didn't mess up
  hue => color.h;
  updateClient(z);
}


fun void slewColors(int hue) {
  <<< "slewing" >>>;
  for( 0 => int z; z < targets; z++ ) 
  {  
    //calculate index
    if (HSV.isWarm(hue))
    {
      spork ~slewIdxColor(z, HSV.getWarm());
    }
    else if (HSV.isCool(hue))
    {
      spork ~slewIdxColor(z, HSV.getCool());
    }
    else if (HSV.isGreen(hue))
    {
      spork ~slewIdxColor(z, HSV.getGreen());
    }
  }

  20::second => now; //wait
}


/************************************************************************* IO */
fun void keyboard()
{
    // the device number to open
  0 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msg;

  // open keyboard
  if( !hi.openKeyboard( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "keyboard '", hi.name(), "' ready" >>>;
  // infinite event loop

  while( true )
  {
    // wait on event
    hi => now;

    // get one or more messages
    while( hi.recv( msg ) )
    {
      if (msg.isButtonDown())
      {
        <<< msg.which >>>;

        //r
        if (msg.which == 21)
        {
          spork ~slewColors(HSV.getWarm());
        }

        //g
        if (msg.which == 10)
        {
          spork ~slewColors(HSV.getGreen());
        }

        //b
        if (msg.which == 5)
        {
          spork ~slewColors(HSV.getCool());
        }

        //y
        if (msg.which == 28)
        {

        }

        // SCALE SHIFTING
        //p
        if (msg.which == PENTATONIC)
        {
          //shift to pentatonic scale
          spork ~gridinit(PENTATONIC);
        }

        //p
        if (msg.which == HIRAJOSHI)
        {
          //shift to hirajoshi scale
          spork ~gridinit(HIRAJOSHI);
        }

        //a
        if (msg.which == AMINOR)
        {
          //shift to aminor scale
          spork ~gridinit(AMINOR);
        }

        //d
        if (msg.which == DMINOR)
        {
          //shift to dminor scale
          spork ~gridinit(DMINOR);
        }

        //ADSR control

        //z
        if (msg.which == 29)
        {
          <<< "A: 20000 D: 0     S: 1 R: 10000" >>>;
          20000 => attackMs;
          0     => decayMs;
          1     => sustainGain;
          10000 => releaseMs;
        }

        //x
        if (msg.which == 27)
        {
          <<< "A: 10000 D: 10000 S: 0.1 R: 10000" >>>;
          10000 => attackMs;
          10000 => decayMs;
          0.1     => sustainGain;
          5000 => releaseMs;
        }

        //c
        if (msg.which == 6)
        {
          <<< "A: 1000  D: 1000  S: 0.8 R: 1000" >>>;
          1000  => attackMs;
          1000  => decayMs;
          0.8  => sustainGain;
          1000 => releaseMs;
        }

        //v
        if (msg.which == 25)
        {
          <<< "A: 100   D: 100   S: 0.1 R: 1000" >>>;
          100  => attackMs;
          100  => decayMs;
          0.1  => sustainGain;
          1000 => releaseMs;
        }
      }
    }
  }
}

/******************************************************************** Control */
netinit();
initscales();
gridinit(HIRAJOSHI);
targetinit(); 

spork ~handleClient();
spork ~handleAction();
spork ~sendClock();


keyboard();