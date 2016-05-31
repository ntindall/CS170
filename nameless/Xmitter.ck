public class Xmitter
{
  // send objects
  OscSend backing[16];
  // number of targets (initialized by init)
  int num_targets;
  // port
  6449 => int port;

  3 => int NUM_BASS;
  int bassIndexes[NUM_BASS];

  5 => int NUM_IN_FRONT;
  7 => int NUM_IN_BACK;

  fun void init(string arg)
  {
    if (arg == "local" || arg == "l" || arg == "localhost")
    {
      <<< "Initializing Xmitter for local" >>>;
      1 => num_targets;

      //write into the bassIndexes array negative numbers if you want less than
      //NUM_BASS basses (handled as special case by the sendBass function)
      [0, 0, 0] @=> bassIndexes;
      backing[0].setHost ( "localhost", port );
    } else 
    {
      <<< "Initializing Xmitter for non-local" >>>;

      2 => num_targets;

      backing[0].setHost ( "localhost", port);
      backing[1].setHost ( "Trijeet.local", port);
      backing[2].setHost ( "HipstersMustDie.local", port);
      
      /*
      //NOTE: REMEMBER TO MODIFY TARGET VALUE OR WILL AOOBE
      12 => num_targets;

      //subwoofers... chowder, lasagne, and kimchi
      [2, 5, 11] @=> bassIndexes;

      //NOTE: CONFIGURED SPECIFICALLY WITH BING IN MIND!!!
      backing[0].setHost ( "spam.local", port );
      backing[1].setHost ( "pho.local", port );
      backing[2].setHost ( "chowder.local", port );
      backing[3].setHost ( "vindaloo.local", port );
      backing[4].setHost ( "jambalaya.local", port );
      backing[5].setHost ( "lasagna.local", port );
      backing[6].setHost ( "nachos.local", port );
      backing[7].setHost ( "foiegras.local", port );
      backing[8].setHost ( "meatloaf.local", port );
      backing[9].setHost ( "hamburger.local", port );
      backing[10].setHost ( "albacore.local", port );
      backing[11].setHost ( "kimchi.locak", port)
      */
    }
  }

  fun int targets()
  {
    return num_targets;
  }

  fun OscSend @ at(int i)
  {
    return backing[i];
  }

  fun int[] basses()
  {
    return bassIndexes;
  }

  fun int front()
  {
    return NUM_IN_FRONT;
  }

  fun int back()
  {
    return NUM_IN_FRONT;
  }
}