//name: nameless-go.ck
//Nathan james Tindall


// print
<<< "-----------------", "" >>>;
<<< "nameless - v0.0", "" >>>;
<<< "-----------------", "" >>>;
// print channels
<<< "* channels:", dac.channels() >>>;



// receiver
fun void network()
{
  // create our OSC receiver
  OscRecv recv;
  // use port 6449
  6449 => recv.port;
  // start listening (launch thread)
  recv.listen();

  // create an address in the receiver, store in new variable
  recv.event( "/slork/synch/grid, f" ) @=> OscEvent oe;

  // count
  0 => int count;
  float gain;

  // infinite event loop
  while ( true )
  {
      // wait for event to arrive
      oe => now;

      // count
      if( count < 5 ) count++;
      if( count < 4 ) <<< ".", "" >>>;
      else if( count == 4 ) <<< "network ready...", "" >>>;

      // grab the next message from the queue. 
      while( oe.nextMsg() != 0 )
       {
        // get gain
        oe.getFloat() => gain;

        <<< gain >>>;
      }
  }
}

network();