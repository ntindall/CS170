
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
4 => int height;
8 => int width;

//zero initialized
RGB grid[32];

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
  <<< "r:", var.r, " g: ", var.g, " b: ", var.b >>>;
}

fun void printPoint(int id, Point @ pos) {
    <<< "ID: ", id, " at x: ", pos.x, " y: ", pos.y >>>;
}

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
            printPoint(z, curPos);
            printRGB(grid[curPos.y*width+curPos.x]);

            // start the message...
            //id r g b
            xmit[z].startMsg( "/slork/synch/grid", "i i i i" );

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