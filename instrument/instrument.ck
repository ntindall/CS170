
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

fun void beep(int deltaX) {
  deltaX / 2 => deltaX; //make mouse a little less sensitive
  <<< deltaX >>>;
  SinOsc s => ADSR a => reverbs[Math.abs(deltaX) % N_CHANS];
  a.set(200::ms, 50::ms, Math.random2f(0.1,0.2), 10::ms);

  if (deltaX > 0) {
    //upper bound
    Math.max(1, s.freq() * deltaX) => float f;
    //lower bound
    Math.min(f, 16000) * register => s.freq;

    for (int i; i < 4; i++) {
      a.keyOn();
      250::ms => now;
      a.keyOff();
      250::ms => now;
    }
  } else {
    Math.max(55, s.freq() * register / Math.abs(deltaX)) => s.freq;

    for (int i; i < 2; i++) {
      a.keyOn();
      500::ms => now;
      a.keyOff();
      500::ms => now;
     }
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
              if( msgM.deltaX )
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
              register + 0.5 => register;
              <<< "[!] REGISTER CHANGE: UP" >>>;
              <<< "[!] " + register >>>;
            } 
            if (msg.which == 81) { //down
              register - 0.5 => register;
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
