tofloader dcam;
DepthCloud cloud;
PShape shp;
float xrot = 0, yrot = 0, scl=1.5;
int dmode=-1;

void setup()
{
  byte[] df;
  size(800,600,P3D);
  dcam = new tofloader();
  df = loadBytes("leaves.dcam");
  dcam.loadFromBytes(df);
  println("Depth: "+dcam.dmin+" --> "+dcam.dmax);
  println("YPR: "+dcam.yaw+", "+dcam.pitch+", "+dcam.roll);
  cloud = new DepthCloud(dcam);
  cloud.startX = 150;
  cloud.endX = dcam.dwidth - 100;
  cloud.startY = 50;
  cloud.endY = dcam.dheight - 50;
  cloud.maxDepth = 270;
  cloud.makeDepthCloud();
  cloud.correctRollPitch();
  cloud.centreX();
  cloud.centreY();
  cloud.centreZ();
  println("Points: "+cloud.vertices.length);
  noSmooth();
  makeShape(0);
  hint(DISABLE_DEPTH_MASK);
}

void draw()
{
  int c;
  background(0,0,0);
  ambientLight(50, 50, 50);
  translate(width/2, height/2, 0);
  rotateX(xrot);
  rotateY(yrot);
  scale(scl);
  shape(shp);
}

void makeShape(int ctype)
{
  int r=0,g=0,b=0;
  dmode=ctype;
  shp = createShape();
  shp.beginShape(POINTS);
  shp.strokeCap(SQUARE);
  shp.strokeWeight(5);
  for(int c=0; c<cloud.vertices.length; c++)
  {
    if(ctype==0)
    {
      r=(int)map(cloud.vertices[c][2],cloud.minZ,cloud.maxZ,255,0);
      g=0;
      b=(int)map(cloud.vertices[c][2],cloud.minZ,cloud.maxZ,0,255);
    }
    if(ctype==1)
    {
      r=(int)map(cloud.confidence[c],cloud.minConf,cloud.maxConf,0,255);
      g=r;
      b=r;
    }
    shp.stroke(r,g,b);
    shp.vertex(cloud.vertices[c][0],cloud.vertices[c][2],-cloud.vertices[c][1]);
  }
  shp.endShape();
}

void mouseDragged()
{
  if(mouseX>=0 && mouseX<width && mouseY>=0 && mouseY<height)
  {
    xrot = map(mouseY, 0, height, PI/2, -PI/2);
    yrot = map(mouseX, 0, width, -PI/2, PI/2);
  }
}

void keyReleased()
{
  switch(key)
  {
    case 'c':   if(dmode!=0) makeShape(0); break;
    case 'd':   if(dmode!=1) makeShape(1); break;
    case '-':   if(scl>0.2) scl-=0.1; break;
    case '+':   if(scl<3) scl+=0.1; break;
  }
}
