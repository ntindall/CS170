//name: nameless-go.ck
//Nathan james Tindall

// print
<<< "-----------------", "" >>>;
<<< "nameless - v0.0", "" >>>;
<<< "-----------------", "" >>>;
// print channels
<<< "* channels:", dac.channels() >>>;

if (me.arg(0) == "")
{
  <<< "You must specify the name of the server" >>>;
  <<< "- for local mode: \"local\"" >>>;
  <<< "- otherwise: the name of the machine running the server code." >>>;
  me.exit();
}

//instantiated by first/subsequent server message
int id;

int r;
int g;
int b;

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
  recv.event( "/slork/io/grid, s") @=> OscEvent ge;

  // count
  0 => int count;

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

        r => int old_r;
        // get gain
        oe.getInt() => id;
        oe.getInt() => r;

        if (r != old_r) {
          spork ~drone();
        }

        oe.getInt() => g;
        oe.getInt() => b;

       // <<< r,g,b >>>;
      }

      // grab the next message from the queue. 
      while( ge.nextMsg() != 0 )
      {
        // get gain
        ge.getString() => string grid;
        <<< grid >>>;
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

  me.arg(0) => string host;
  if ((host == "l") || (host == "local")) {
    "localhost" => host;
  }

  // aim the transmitter at port
  xmit.setHost ( host, port );

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
        id => xmit.addInt;

        if (msg.which == 7) {
          //rearticulate drone
          spork ~drone();
        }

        //up
        if (msg.which >= 79 && msg.which <= 82)
        {

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
}

fun void drone()
{
  BeeThree rOsc => ADSR a => LPF l => dac;
  l.freq(300);
  rOsc.lfoSpeed(1);
  rOsc.lfoDepth(0.01);
  rOsc.controlOne(1);
 // SinOsc gOsc => a;
 // SinOsc bOsc => a;

  1 => rOsc.noteOn;
  a.set(5::second, 5::second, 0.1, 5::second);
  <<< r, g, b >>>;
  rOsc.freq(Std.mtof(r));
  //gOsc.freq(Std.mtof(g));
  //bOsc.freq(Std.mtof(b));

  a.keyOn();
  10::second => now;
  a.keyOff();
  5::second => now;

  1 => rOsc.noteOff;
}

spork ~network();
client();
