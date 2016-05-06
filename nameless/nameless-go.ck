//name: nameless-go.ck
//Nathan james Tindall

// print
<<< "-----------------", "" >>>;
<<< "nameless - v0.0", "" >>>;
<<< "-----------------", "" >>>;
// print channels
<<< "* channels:", dac.channels() >>>;

//instantiated by first/subsequent server message
int id;

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
  recv.event( "/slork/synch/synth, i i i i" ) @=> OscEvent oe;

  // count
  0 => int count;
  int r;
  int g;
  int b;

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
        oe.getInt() => id;
        oe.getInt() => r;
        oe.getInt() => g;
        oe.getInt() => b;

       // <<< r,g,b >>>;
      }
  }
}

fun void client()
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

  // send objects
  OscSend xmit;
  // number of targets
  1 => int targets;
  // port
  6451 => int port;

  // aim the transmitter at port
  xmit.setHost ( "localhost", port );

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
        // a message is kicked as soon as it is complete 
        // - type string is satisfied and bundles are closed
        xmit.startMsg("/slork/synch/move", "i i i");
        0 => xmit.addInt;

        //up
        if (msg.which == 82) 
        {
          1 => xmit.addInt;
          0 => xmit.addInt;
        }
        //down
        if (msg.which == 81) 
        {
          -1 => xmit.addInt;
          0  => xmit.addInt;
        }
        //left
        if (msg.which == 80) 
        {          
          0 => xmit.addInt;
          -1  => xmit.addInt;

        }
        //right
        if (msg.which == 79)
        {
          0 => xmit.addInt;
          1  => xmit.addInt;
        }
      }
    }
  }
}

spork ~network();
client();
