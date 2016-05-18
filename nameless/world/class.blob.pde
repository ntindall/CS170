class Blob {
  float x, y, radius;
  float startX, startY, stepSize;
  int id;
  Colors colors = new Colors();
  float alpha = 0;
  float halo = 0;

  Blob(int _id, float _x, float _y, float _size) {
    stepSize = _size;
    float offset = stepSize / 2;
    startX = _x + offset;
    startY = _y - offset;
    radius = 10;
    x = startX;
    y = startY;
    id = _id;
  }

  void setX(float x) {
    float _x = startX + (stepSize * x);
    Ani.to(this, 5, "x", _x);
  }

  void setY(float y) {
    float _y = startY - (stepSize * y);
    Ani.to(this, 5, "y", _y);
  }

  void hide() {
    Ani.to(this, 2, "alpha", 0);
  }

  void show() {
    Ani.to(this, 2, "alpha", 255);
  }

  void draw() {
    fill(colors.getById(id), (halo * 255));
    ellipse(x, y, radius * (1 + halo), radius * (1 + halo));
    fill(colors.getById(id), alpha);
    ellipse(x, y, radius, radius);
  }
}