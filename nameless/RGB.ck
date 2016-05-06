public class RGB {

  16 => int MAX_OCCUPANTS; 
  int r;
  int g;
  int b;
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