
// value of 8th
4096::samp => dur T;

// send objects
OscSend xmit[16];
// number of targets
1 => int targets;
// port
6449 => int port;

// aim the transmitter at port
xmit[0].setHost ( "localhost", port );

// dimensions
10 => int height;
10 => int width;
string gridString;
for (int i; i < height * width; i++) {
  "i " +=> gridString;
}

//zero initialized, heap memory
new RGB[height*width] @=> RGB @ grid[];

//The location of each target
Point positions[targets];

int x;
int y;
int z;

class Point {
    int x;
    int y;
}

fun void printRGB(RGB @ var) {
  <<< "r:", var.r, " g: ", var.g, " b: ", var.b, " o: ", var.isOccupied()>>>;
}

fun void printPoint(int id, Point @ pos) {
    <<< "ID: ", id, " at x: ", pos.x, " y: ", pos.y >>>;
}

fun void init()
{
  for( 0 => y; y < height; y++ ) 
  {
    for( 0 => x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;

      Math.random2(20,90) => grid[idx].r;
      Math.random2(20,90) => grid[idx].g;
      Math.random2(20,90) => grid[idx].b;

    }
  }
}

string cache;
fun string printGrid() {

  "----------------------------\n" => string result;
  for( 0 => y; y < height; y++ ) 
  {
    for( 0 => x; x < width; x++ ) 
    {
      //calculate index
      y*width + x => int idx;

      if (grid[idx].isOccupied()) {
        "1  " +=> result;
      } else {
        "0  " +=> result;
      }
    }
    "\n" +=> result;
  }

  result => cache;

  return result;
}

fun void server()
{
  // infinite time loop
  while( true ) 
  {
    for( 0 => y; y < height; y++ ) 
    {
      for( 0 => x; x < width; x++ ) 
      {
          for( 0 => z; z < targets; z++ ) 
          {  
              positions[z] @=> Point curPos; 
              //printPoint(z, curPos);
              //printRGB(grid[curPos.y*width+curPos.x]);

              // start the message...
              //id r g b
              xmit[z].startMsg( "/slork/synch/synth", "i i i i" );

              // a message is kicked as soon as it is complete 
              // - type string is satisfied and bundles are closed
              z                               => xmit[z].addInt;
              grid[curPos.y*width+curPos.x].r => xmit[z].addInt;
              grid[curPos.y*width+curPos.x].g => xmit[z].addInt;
              grid[curPos.y*width+curPos.x].b => xmit[z].addInt;

          }

          // advance time
          T => now;
      }
    }
  }
}

fun void receiver()
{
  // create our OSC receiver
  OscRecv recv;
  // use port 6449
  6451 => recv.port;
  // start listening (launch thread)
  recv.listen();

  // create an address in the receiver, store in new variable
  //id x y
  recv.event( "/slork/synch/move, i i i" ) @=> OscEvent oe;

  while ( true )
  {
    oe => now;

    while ( oe.nextMsg() != 0 )
    {
      oe.getInt() => int id;
      oe.getInt() => int dX;
      oe.getInt() => int dY;

      //unset occupied for old position
      0 => grid[positions[id].y*width+positions[id].x].who[id];

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
    }
  }
}

fun RGB avgNeighbors(int x, int y, RGB @ cel) {
  RGB average;
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

      grid[idx].r +=> average.r;
      grid[idx].g +=> average.g;
      grid[idx].b +=> average.b;
      //okay, safe to index now.

    }
  }

  average.r / 8 => average.r;
  average.g / 8 => average.g;
  average.b / 8 => average.b;

  return average;
}

fun void gridEvolution()
{
  while ( true ) 
  {
    printGrid();
    <<< cache >>>;

    new RGB[height*width] @=> RGB @ nextGrid[];
    for( 0 => y; y < height; y++ ) 
    {
      for( 0 => x; x < width; x++ ) 
      {
        //calculate index
        y*width + x => int idx;

        if (grid[idx].isOccupied()) {
          avgNeighbors(x, y, grid[idx]) @=> grid[idx];

        }
      }
    }

    //evolution time
    1::second => now;
  }
}


//control
init();
spork ~server();
spork ~receiver();
gridEvolution();