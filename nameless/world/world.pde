import oscP5.*;
import de.looksgood.ani.*;

// globals
boolean serverReady = false;

// osc
OscP5 oscP5;

// data
Colors colors = new Colors();

// update variables as per world
int N_PLAYERS = 1;
int WIDTH = 14;
int HEIGHT = 14;

float WORLD_SIZE = 960;
float CELL_SIZE = WORLD_SIZE / WIDTH;

// geometry
Blob[] blobs = new Blob[N_PLAYERS];
Grid grid;

void setup() {
  size(1920, 1080, P2D);
  smooth(8);
  noStroke();
  noCursor();
  // fullScreen(2);
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(60);

  Ani.init(this);
  
  oscP5 = new OscP5(this, 4242);

  initWorld();
  
  /* osc plug service
   * osc messages with a specific address pattern can be automatically
   * forwarded to a specific method of an object. in this example 
   * a message with address pattern /test will be forwarded to a method
   * test(). below the method test takes 2 arguments - 2 ints. therefore each
   * message with address pattern /test and typetag ii will be forwarded to
   * the method test(int theA, int theB)
   */
  oscP5.plug(this, "resetWorld", "/nameless/graphics/init");
  oscP5.plug(this, "updatePlayer", "/nameless/graphics/player/move");
  oscP5.plug(this, "jumpPlayer", "/nameless/graphics/player/jump");
  oscP5.plug(this, "showPlayer", "/nameless/graphics/player/enter");
  oscP5.plug(this, "hidePlayer", "/nameless/graphics/player/exit");
  oscP5.plug(this, "cellFadeIn", "/nameless/graphics/cell/fadeIn");
  oscP5.plug(this, "cellFadeOut", "/nameless/graphics/cell/fadeOut");
}

void draw() {
  background(0);

  if (grid != null)
    grid.draw();

  if (blobs != null)
    for (int i = 0; i < N_PLAYERS; i++) {
      Blob blob = blobs[i];
      if (blob != null)
        blob.draw();
    }
}

void initWorld() {
  float _x = (width / 2) - (WORLD_SIZE / 2);
  float _y = (height / 2) + (WORLD_SIZE / 2);

  blobs = new Blob[N_PLAYERS];

  for (int id = 0; id < N_PLAYERS; ++id) {
    blobs[id] = new Blob(id, _x, _y, CELL_SIZE);
    blobs[id].hide();
    blobs[id].worldAlive(true);
  }

  grid = new Grid(WIDTH, N_PLAYERS, WORLD_SIZE, CELL_SIZE, _x, _y);
  grid.worldAlive(true);

  println("players: "+N_PLAYERS);
}

void resetWorld(int n, int width, int height) {
  if (n != N_PLAYERS)
    N_PLAYERS = n;

  if (height != HEIGHT)
    HEIGHT = height;

  if (width != WIDTH)
    WIDTH = width;

  serverReady = true;

  initWorld();
}

void showPlayer(int id) {
  blobs[id].show();
}

void hidePlayer(int id) {
  blobs[id].hide();
}

void jumpPlayer(int id) {
  blobs[id].jump();
}

void updatePlayer(int id, int x, int y, int h, int s, int b) {
  blobs[id].setX(x);
  blobs[id].setY(y);
  blobs[id].setColor(h, s, b);
  grid.updateCell(id, x, y, h, s, b);
}

void cellFadeIn(int id, int x, int y, int time) {
  grid.cellFadeIn(id, x, y, time);
}

void cellFadeOut(int id, int x, int y, int time) {
  grid.cellFadeOut(id, x, y, time);
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage oscMsg) {
  /* with theOscMessage.isPlugged() you check if the osc message has already been
   * forwarded to a plugged method. if theOscMessage.isPlugged()==true, it has already 
   * been forwared to another method in your sketch. theOscMessage.isPlugged() can 
   * be used for double posting but is not required.
  */  
  if (oscMsg.isPlugged() == false) {
    /* print the address pattern and the typetag of the received OscMessage */
    println("### received an osc message.");
    println("### addrpattern\t" + oscMsg.addrPattern());
    println("### typetag\t"+ oscMsg.typetag());
  }
}