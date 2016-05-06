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

// strengths
[ 1.0, 0.5, 0.8, 0.4, 0.9, 0.6, 0.6, 0.5,
  0.7, 0.4, 0.8, 0.6, 0.9, 0.5, 0.5, 0.9,
  0.9, 0.5, 0.6, 0.5, 0.8, 0.6, 0.8, 0.5,
  0.5, 0.5, 0.8, 0.5, 1.0, 0.8, 0.5, 0.5 ] @=> float mygains[];

int x;
int y;
int z;

// infinite time loop
while( true ) 
{
  for( 0 => y; y < height; y++ ) 
  {
    for( 0 => x; x < width; x++ ) 
    {
        for( 0 => z; z < targets; z++ ) 
        {
            // start the message...
            xmit[z].startMsg( "/slork/synch/grid", "f" );

            // a message is kicked as soon as it is complete 
            // - type string is satisfied and bundles are closed
            mygains[y*width+x] => xmit[z].addFloat;
        }

        // advance time
        T => now;
    }
  }
}