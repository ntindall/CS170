
// value of 8th
4096::samp => dur T;

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

// dimensions
10 => int height;
10 => int width;

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
    2 => targets;
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
    <<< "ID: ", id, " at x: ", pos.x, " y: ", pos.y >>>;
}

fun GridCell[] deepCopy (GridCell @ g[])
{
  new GridCell[height*width] @=> GridCell @ next[];
  for( 0 => int y; y < height; y++ ) 
  {
    for( 0 => int x; x < width; x++ ) 
    {
      y*width + x => int idx;

      g[idx] @=> next[idx];
    }
  }

  return next;
}


[60-24,61-24,65-24,66-24,70-24,60-12,61-12,65-12,66-12,70-12] @=> int scale[];

fun void gridinit()
{
  for( 0 => int y; y < height; y++ ) 
  {
    for( 0 => int x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;

      scale[x] + y * 12 => grid[idx].pitch;
    }
  }

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

fun void updateClients()
{
  for( 0 => int z; z < targets; z++ ) 
  {  
      positions[z] @=> PlayerState curPlayer; 
      printPlayerState(z, curPlayer);
      printGridCell(grid[curPlayer.y*width+curPlayer.x]);

      // start the message...
      //id midi r g b
      xmit[z].startMsg( "/slork/synch/synth", "i i i i i s" );

      // a message is kicked as soon as it is complete 
      // - type string is satisfied and bundles are closed
      z                                   => xmit[z].addInt;
      grid[curPlayer.y*width+curPlayer.x].pitch => xmit[z].addInt;
      curPlayer.color.h                            => xmit[z].addInt;
      curPlayer.color.s                            => xmit[z].addInt;
      curPlayer.color.v                            => xmit[z].addInt;

      printGrid(curPlayer.y*width+curPlayer.x) => xmit[z].addString;
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

/*
fun GridCell avgNeighbors(int x, int y, GridCell @ cel) {
  GridCell average;
  cel.who @=> average.who;

  for (-1 => int i; i <= 1; i++)
  {
    for (-1 => int j; j <= 1; j++)
    {
      if ((i == j) && (i == 0)) continue;

      x + i => int neighX;
      y + j => int neighY;

      if (neighX > width - 1) 0 => neighX;
      if (neighX < 0) width - 1 => neighX;

      if (neighY > height - 1) 0 => neighY;
      if (neighY < 0) height - 1 => neighY;

      neighY * width + neighX => int idx;

      grid[idx].h +=> average.h;
      grid[idx].s +=> average.s;
      grid[idx].v +=> average.v;
      //okay, safe to index now.

    }
  }

  average.h / 8 => average.h;
  average.s / 8 => average.s;
  average.v / 8 => average.v;

  return average;
}
*/

fun void gridEvolution()
{
  while ( true ) 
  {
    <<< printGrid(-1) >>>;

    deepCopy(grid) @=> GridCell @ nextGrid[];

    0 => int mutatedGrid;
    for( 0 => int y; y < height; y++ ) 
    {
      for( 0 => int x; x < width; x++ ) 
      {
        //calculate index
        y*width + x => int idx;

        if (now % 20::second == 0::second && grid[idx].isOccupied()) {
          <<< "[!]\n[!]\n[!]\n" >>>;
          <<< "Terraforming!!!" >>>;

          //important note... if grid cell changes while someone is on it, they
          //will be notified IMMEDIATELY and could potentially spork/create
          //sound (as they normally would upon a position / pitch change)
          //avgNeighbors(x, y, grid[idx]) @=> nextGrid[idx];
          1 => mutatedGrid;

          <<< "[!]\n[!]\n[!]\n" >>>;

        } 
      }
    }

    if (mutatedGrid == 1) nextGrid @=> grid;

    //xmit
    /*
    for( 0 => int z; z < targets; z++ ) 
    {  
      positions[z].y*width + positions[z].x => int idx;

      xmit[z].startMsg( "/slork/io/grid", "s" );
      printGrid(idx) => xmit[z].addString;
    }
    */

    spork ~updateClients();

    //evolution time
    10::ms => now;
  }
}

fun void updateGrid()
{
  <<< printGrid(-1) >>>;

  deepCopy(grid) @=> GridCell @ nextGrid[];

  0 => int mutatedGrid;
  for( 0 => int y; y < height; y++ ) 
  {
    for( 0 => int x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;

      if (now % 20::second == 0::second && grid[idx].isOccupied()) {
        <<< "[!]\n[!]\n[!]\n" >>>;
        <<< "Terraforming!!!" >>>;

        //important note... if grid cell changes while someone is on it, they
        //will be notified IMMEDIATELY and could potentially spork/create
        //sound (as they normally would upon a position / pitch change)
        //avgNeighbors(x, y, grid[idx]) @=> nextGrid[idx];
        1 => mutatedGrid;

        <<< "[!]\n[!]\n[!]\n" >>>;

      } 
    }
  }

  if (mutatedGrid == 1) nextGrid @=> grid;
}

/******************************************************************** Control */
netinit();
gridinit();

spork ~handleClient();
spork ~handleAction();

while (true) 1::day => now;