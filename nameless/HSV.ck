public class HSV {
  0 => int h;
  0 => int s;
  0 => int v;

  fun static int isCool(int h)
  {
    return (h >= 180 && h < 300);
  }

  fun static int isWarm(int h)
  {
    return (h >= 0 && h < 60 || h >= 300);
  }

  fun static int isGreen(int h)
  {
    return (h >= 60 && h < 180);
  }

  fun static int getCool()
  {
    return Math.random2(180, 299);

  }

  fun static int getWarm()
  {
    if (Math.random2(0,1) == 1)
    {
      return Math.random2(0,59);
    } else
    {
      return Math.random2(300, 359);
    }
  }

  fun static int getGreen()
  {
    return Math.random2(60,179);
  }

}

while (true) 1::day => now;