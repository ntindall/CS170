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
      //TO CONFIG... assumes that hosts 0 1 2 are the three hosts with
      //subwoofers... 
      [0, 1, 2] @=> bassIndexes;

      2 => num_targets;

      backing[0].setHost ( "localhost", port);
      backing[1].setHost ( "Trijeet.local", port);
      backing[2].setHost ( "HipstersMustDie.local", port);
      
      /*
      //NOTE: REMEMBER TO MODIFY TARGET VALUE OR WILL AOOBE
      11 => num_targets;
      backing[0].setHost ( "albacore.local", port );
      backing[1].setHost ( "kimchi.local", port );
      backing[2].setHost ( "jambalaya.local", port );
      backing[3].setHost ( "vindaloo.local", port );
      backing[4].setHost ( "spam.local", port );
      backing[5].setHost ( "hamburger.local", port );
      backing[6].setHost ( "pho.local", port );
      backing[7].setHost ( "foiegras.local", port );
      backing[8].setHost ( "lasagna.local", port );
      backing[9].setHost ( "meatloaf.local", port );
      backing[10].setHost ( "chowder.local", port );
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
}