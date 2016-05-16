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

/******************************************************************** Welcome */

<<< 
"Control Information for Players

 - <SPACE>             to begin / enter world
 - ^v<> keys           to navigate world
 - d                   to rearticulate drone (on your current position)

It is possible that the state of the world could change while you are on it.
The server may change global parameters and notify clients immediately.

By moving to a new cell, you will generate a tone. The envelope of the tone is
tuned by the server. Some envelopes will tend towards more or less movement.
"
>>>;


/******************************************************************** Globals */

//instantiated by first/subsequent server message
int id;

//global parameter for controlling when client should begin entering sound
//users should press spacebar to 'enter' the grid
int hasEntered;

//r g b MIDI values
int pitch;

int h;
int s;
int v;

Event playerMoved;

// osc handle for server
OscSend xmit;
// server listening port
6451 => int port;

me.arg(0) => string host;
if ((host == "l") || (host == "local")) {
  "localhost" => host;
}

// aim the transmitter at port
xmit.setHost ( host, port );

/******************************************************************** Network */

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
  //id pitch r g b
  recv.event( "/slork/synch/synth, i i i i i s" ) @=> OscEvent oe;

  // count
  0 => int count;

  /*
  while (hasEntered == 0)
  {
    100::ms => now;
  }
  */

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

        pitch => int old_pitch;

        // get gain
        oe.getInt() => id;
        oe.getInt() => pitch;

        if ((pitch != old_pitch) && (hasEntered)) {
          spork ~drone();
        }

        oe.getInt() => h;
        oe.getInt() => s;
        oe.getInt() => v;

        <<< pitch, h,s,v >>>;

        <<< oe.getString() >>>;
      }
  }
}

fun void xmitMove(int deltaX, int deltaY)
{
  // a message is kicked as soon as it is complete 
  // - type string is satisfied and bundles are closed
  xmit.startMsg("/slork/synch/move", "i i i");
  id => xmit.addInt;
  deltaX => xmit.addInt;
  deltaY => xmit.addInt;
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

        if (msg.which == 44)
        {
          1 => hasEntered;
          xmitMove(0, 0);
          spork ~drone();
        }

        if ((hasEntered == 1) && (msg.which == 7))
        {
          //rearticulate drone
          spork ~drone();
        }

        if (hasEntered == 1)
        {
          //d, rearticulate drone
          if (msg.which == 7) spork ~drone();

          /************************************************ ARROW KEY CONTROL */
          //up
          if (msg.which == 82) xmitMove(1, 0);
          //down
          if (msg.which == 81) xmitMove(-1, 0);
          //left
          if (msg.which == 80) xmitMove(0, -1);
          //right
          if (msg.which == 79) xmitMove(0, 1);

          playerMoved.broadcast();
        }
      }
    }
  }
}

/*********************************************************** Sound Production */

Gain globalG => dac;
fun void drone()
{

  int lpfCutoff;

  //determine color type of current cell.. do something (more?) intelligent
  if (h >= 0 && h < 60 || h > 300)
  {
    //warmest
    h => int temp;
    if (temp > 300) 360 - temp => temp;

    //okay. we have a number between 60 and 0
    12000 - temp*100 => lpfCutoff;
    //bound between 12000 and 3000

  }
  if (h >= 60 && h < 180)
  {
    3000 - (h - 60)*15 => lpfCutoff;
    //earthy green /yellow/cyan
    //bound to 3000 and 1200
  }
  if (h >= 180 && h < 300)
  {
    (1200 - (h - 180)*7.5) $ int => lpfCutoff;
    //bound between 1200 and 300
    //coolest
  }


  ADSR a => LPF l =>  globalG;
  l.freq(lpfCutoff);

  BeeThree cool => Gain coolGain => a;
  coolGain.gain(0.1);
  cool.lfoSpeed(1);
  cool.lfoDepth(0.01);
  cool.controlOne(1);

  /*
  SqrOsc warm => Gain warmGain => a;
  warmGain.gain(0.1);
  */

  1 => cool.noteOn;
  a.set(20::second, 0::second, 1, 10::second);
  Std.mtof(pitch) => cool.freq;

  a.keyOn();
  // 10::second => now;

  playerMoved => now;

  a.keyOff();
  10::second => now;

  1 => cool.noteOff;
}

spork ~network();
client();
