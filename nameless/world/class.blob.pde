class Blob {
  float x, y, radius;
  int id;
  Colors colors = new Colors();
  float alpha = 0;
  float halo = 0;

  Blob(int _id) {
    x = 300;
    y = 400;
    radius = 10;
    id = _id;
  }

  void setX(float x) {
    float _x = 300 + (50 * x);
    Ani.to(this, 0.1, "x", _x);
  }

  void setY(float y) {
    float _y = 400 - (50 * y);
    Ani.to(this, 0.1, "y", _y);
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