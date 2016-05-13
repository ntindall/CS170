public class HSV {

  16 => int MAX_OCCUPANTS; 
  int pitch; //MIDI
  int h;
  int s;
  int v;
  int who[MAX_OCCUPANTS]; //hard coded number of max occupants


  fun int isOccupied() 
  {
    for (int i; i < MAX_OCCUPANTS; i++)
    {
      if (who[i] == 1) return true;
    }

    return false;
  }
}

1::day => now;