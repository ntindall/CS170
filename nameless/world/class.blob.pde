class Blob {
  float x, y, radius;
  float startX, startY, stepSize;
  int id;
  // Colors colors = new Colors();
  color col;
  float alpha = 0;
  float halo = 0;

  Blob(int _id, float _x, float _y, float _size) {
    stepSize = _size;
    float offset = stepSize / 2;
    startX = _x + offset;
    startY = _y - offset;
    radius = 20;
    halo = 0.5;
    x = startX;
    y = startY;
    id = _id;
  }

  void setX(float x) {
    float _x = startX + (stepSize * x);
    Ani.to(this, 1, "x", _x);
  }

  void setY(float y) {
    float _y = startY - (stepSize * y);
    Ani.to(this, 1, "y", _y);
  }

  void setColor(int h, int s, int b) {
    col = color(h, s, b);
  }

  void hide() {
    Ani.to(this, 2, "alpha", 0);
  }

  void show() {
    Ani.to(this, 2, "alpha", 100);
  }

  void draw() {
    fill(color(0, 0, 100, 10 * (alpha / 100)));
    ellipse(x, y, radius * (1 + halo), radius * (1 + halo));
    fill(col, alpha);
    ellipse(x, y, radius, radius);
  }
}