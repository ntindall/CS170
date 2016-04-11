//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//------------------------- LISA HELPERS ---------------------------------------
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

.5 => float GRAIN_RAMP_FACTOR;

// max lisa voices
30 => int LISA_MAX_VOICES;

// grain sporkee
fun void grain(LiSa @ lisa,    //UGen       
               dur pos,        //position in buffer
               dur grainLen,   //length of grain
               dur rampUp,     //triangle envelope rampUp
               dur rampDown,   //triangle envelope rampDown
               float rate )    //sample playback rate
{
    // get a voice to use
    lisa.getVoice() => int voice;

    // if available
    if( voice > -1 )
    {
        // set rate
        lisa.rate( voice, rate );
        // set playhead
        lisa.playPos( voice, pos );
        // ramp up
        lisa.rampUp( voice, rampUp );
        // wait
        (grainLen - rampUp) => now;
        // ramp down
        lisa.rampDown( voice, rampDown );
        // wait
        rampDown => now;
    }
    500::ms => now; //decay
}

// load file into a LiSa
fun LiSa load( string filename )
{
    // sound buffer
    SndBuf buffy;
    // load it
    filename => buffy.read;
    
    // new LiSa
    LiSa lisa;
    // set duration
    buffy.samples()::samp => lisa.duration;
    
    // transfer values from SndBuf to LiSa
    for( 0 => int i; i < buffy.samples(); i++ )
    {
        // args are sample value and sample index
        // (dur must be integral in samples)
        lisa.valueAt( buffy.valueAt(i), i::samp );        
    }
    
    // set LiSa parameters
    lisa.play( false );
    lisa.loop( false );
    lisa.maxVoices( LISA_MAX_VOICES );
    
    return lisa;
}


/* PATCH */
dac.channels() => int N_CHANS;

NRev reverbs[N_CHANS];
HPF h[N_CHANS];

for (int i; i < N_CHANS; i++) {
  reverbs[i] => h[i] => dac.chan(i);
  h[i].freq(50);
  reverbs[i].mix(0.05);
}

1 => float register;

//todo... multichannel LiSa
load (me.sourceDir() + "enya2.wav") @=> LiSa lisa;


fun void beep(int deltaX) {
  deltaX / 2 => deltaX; //make mouse a little less sensitive

  lisa => LPF l => reverbs[Math.abs(deltaX) % N_CHANS];

  l.freq(20000);

  //upper bound
//  Math.max(1, deltaX) => float rate;
  //lower bound
  Math.min(Math.abs(deltaX), 8) * register => float rate;

  <<< rate >>>;
  Math.random2(0, 1) => float position;
// TODO, adjust the grain parameters and fix the position... maybe map to
// a x or y parameter to position??? random is not the best.
  grain(lisa,
        position * lisa.duration(),
        500::ms,
        GRAIN_RAMP_FACTOR * 250::ms,
        GRAIN_RAMP_FACTOR * 250::ms,
        rate);
}

fun void mouse() {
  // the device number to open
  0 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msgM;

  // open mouse 0, exit on fail
  if( !hi.openMouse( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "mouse '", hi.name(), "' ready" >>>;

  // infinite event loop
  while( true )
  {
      // wait on HidIn as event
      hi => now;

      // messages received
      while( hi.recv( msgM ) )
      {
          // mouse motion
          if( msgM.isMouseMotion() )
          {
              // axis of motion
              if( msgM.deltaX )
              {
                  
                spork ~beep(msgM.deltaX);
                25::ms => now; //TODO... rate limit the sporking a bit.
                               //what is the optimal value????

                //TODO
                while (hi.recv (msgM)) {
                  //noop
                  //clear queue
                }
              }

          }
      }
  }
}

fun void keyboard() {
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
          // check for action type
          if( msg.isButtonDown() )
          {
            if (msg.which == 82) { //up
              register + 0.1 => register;
              <<< "[!] REGISTER CHANGE: UP" >>>;
              <<< "[!] " + register >>>;
            } 
            if (msg.which == 81) { //down
              register - 0.1 => register;
              <<< "[!] REGISTER CHANGE: DOWN" >>>; 
              <<< "[!] " + register >>>;
            }
          }
          else
          {
              // print
              // <<< "up:", msg.which >>>;
          }
      }
  }
}

/* CONTROL */
spork ~keyboard();
mouse();
