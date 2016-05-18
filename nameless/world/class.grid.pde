class Grid {
  int n;
  float worldSize, cellSize;
  float startX, startY;

  Grid(int _n, float _worldSize, float _cellSize, float _x, float _y) {
    n = _n;
    worldSize = _worldSize;
    cellSize = _cellSize;
    startX = _x;
    startY = _y;
  }

  void draw() {
    stroke(30);
    strokeWeight(5);

    for (int i = 0; i <= n; ++i) {
      line(startX + (cellSize * i), startY, startX + (cellSize * i), startY - worldSize);
      line(startX, startY - (cellSize * i), startX + worldSize, startY - (cellSize * i));
    }

    noStroke();
  }
}