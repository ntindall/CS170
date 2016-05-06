
/* PATCH */
dac.channels() => int N_CHANS;

NRev reverbs[N_CHANS];
HPF h[N_CHANS];

for (int i; i < N_CHANS; i++) {
  reverbs[i] => h[i] => dac.chan(i);
  h[i].freq(50);
  reverbs[i].mix(0.05);
}

//Function to play a grain
fun void grain(SndBuf buf, Envelope e, float duration, int position, float pitch, int randompos, float randpitch, float gain)
{ 
    Math.random2f(pitch-randpitch,pitch+randpitch) => buf.rate;
    Math.random2(position-randompos,position+randompos) => buf.pos;
    gain => buf.gain;
    
    e.keyOn();
    duration*0.6::ms => now;
    e.keyOff();
    duration*0.4::ms => now;
}

fun void grainString(SndBuf buf, Envelope e, float duration, int position, float pitch, int randompos, float randpitch, float gain, int numGrains)
{
    duration $ int * 50  => int advancePerGrain;
    for(0 => int i; i < numGrains; i++)
    {
        position + (i * advancePerGrain) => int grainPos;
        grain(buf, e, duration, grainPos, pitch, randompos, randpitch, gain);
    }
}

fun void beep(int deltaX) {
    <<<deltaX>>>;
    
    //Decide how many grains to play of source file (based on delta X)
    Math.abs(deltaX) * 2 => int numGrains;
    
    //Decide playback rate for grains (based on deltaX, swiping left causes backwards playback)
    //TODO: Maybe we should map pitch to deltaY instead, so we can de-couple the pitch and the number of grains?)
    (deltaX + 1) / 2.0 => float pitch;
    if(pitch < 0)
        1.0 / pitch => pitch;
    //TODO: limits on pitch?
    
    //Set up sound buffer (TODO: may want to not have to load the file again for every new beep)
    SndBuf buf1 => Envelope e; //TODO: I'd like to try adding some of the "glitchy intruder" grain replacement stuff to this instrument
    for(0 => int i; i < N_CHANS; i++)
    {
        e => reverbs[i]; //TODO: variation between channels (different channel per grain in string? All grains on all channels but slightly offset?)
    }
    "enya2.wav" => string file1;
    //"drmario02.dsp.wav" => string file1; //UNCOMMENT HERE TO SWITCH SOURCE FILES
    me.sourceDir() + "/" + file1 => buf1.read;
    
    //Play grain string a set number of times, with a set delay between each playback
    4 => int numDelays;
    for(0 => int i; i < numDelays; i++)
    {
        (numDelays - i) $ float / (2.0 * numDelays $ float) => float gain;
        spork ~ grainString(buf1, e, 75.0, buf1.samples() / 2, pitch, 1000, 0, gain, numGrains);
        500::ms => now;
    }
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
              if( msgM.deltaX && msgM.deltaX != 0)
              {
                  
                  spork ~beep(msgM.deltaX);
                  125:: ms => now;

                  while (hi.recv (msgM)) {
                    //noop
                    //clear queue
                  }
              }

          }
      }
  }
}
mouse();
