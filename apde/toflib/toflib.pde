import android.os.Bundle;

DepthCamera dcam;
IMUOrientation imu;
boolean waitingforimage = false;
PGraphics dgraphic;
PImage photobutton, savebutton;
int pbx, pby, sbx, sby;
boolean havedepthcamera = false;
boolean havecamperm = false;
boolean gotdepth = false;
boolean saved = false;
boolean firsttime = true;
int depthaverages = 1;

void setup()
{
  fullScreen(P2D);
  savebutton = loadImage("savebutton.png");
  savebutton.resize(100, 100);
  photobutton = loadImage("photobutton.png");
  photobutton.resize(150, 150);
  pbx = width - 100;
  pby = height/2;
  sbx = width-100;
  sby = height-100;
  if(hasPermission("android.permission.CAMERA"))
  {
    println("Camera permission already granted.");
    havecamperm = true;
    startCameras();
  }
  else
  {
    requestPermission("android.permission.CAMERA","initPermissions");
  }
}

void draw()
{
  if(!havecamperm)
  {
    background(255,0,0);
    return;
  }
  background(0,0,0);
  if(waitingforimage)
  {
    checkforframe();
  }
  else
  {
    imageMode(CENTER);
    if(gotdepth) image(dgraphic,width/2,height/2);
    if(havedepthcamera)
    {
      image(photobutton, pbx, pby);
      if(gotdepth) if(!saved) image(savebutton, sbx, sby);
    }
  }
}

void onCreate(Bundle savedInstanceState)
{
  orientation(LANDSCAPE);
}

public void onPause()
{
  super.onPause();
}

void onResume()
{
  super.onResume();
}

void onStop()
{
  // We need onStop to ensure we close the camera
  // devices on exiting. But it is also needed to
  // handle orientation changes if we don't have
  // fixed orientations including for the APDE
  // previewer to prevent crashes.
  super.onStop();
  if(havecamperm)
  {
    if(havedepthcamera) dcam.close();
  }
}

void capture()
{
  if(!havecamperm) return;
  if(waitingforimage) return;
  waitingforimage = true;
  gotdepth = false;
  println("YPR: "+imu.yaw+" "+imu.pitch+" "+imu.roll);
  if(havedepthcamera) 
  {
    dcam.numtoaverage = depthaverages;
    dcam.capture(imu.yaw, imu.pitch, imu.roll);
  }
}

void save()
{
  String fname, imname;
  if(!havecamperm) return;
  if(waitingforimage) return;
  fname = dcam.getDateFileName();
  imname = dcam.getDateFileName("png");
  byte[] bts = dcam.makeFileBytes();
  saveBytes(fname, bts);
  dgraphic.save(imname);
  println("Saved to "+fname);
  saved = true;
}

boolean checkforframe()
{
  if(!havecamperm) return false;
  if(waitingforimage)
  {
    if(havedepthcamera)
    {
      if(dcam.gotframe && !gotdepth)
      {
        println("Got depth frame!");
        println("Size: "+dcam.width+" ,"+dcam.height);
        println(dcam.depth.length+" bytes");
        println("");
        makeDepthGraphics();
        gotdepth = true;
        saved = false;
        waitingforimage = false;
      }
    }
    if(!waitingforimage) return true;
  }
  return false;
}

void startCameras()
{
  imu = new IMUOrientation(this.getContext());
  dcam = new DepthCamera(this.getContext());
  dcam.begin();
  delay(500);
  if(dcam.havedepthcamera)
  {
    dcam.print();
    havedepthcamera = true;
  }
  else
  {
    println("No depth camera found!");
    havedepthcamera = false;
  }
  delay(500);
  byte[] tf = loadBytes("test.dcam");
  gotdepth = dcam.loadFromBytes(tf);
  if(gotdepth) makeDepthGraphics();
}

void keyPressed()
{
  if(keyCode == 24) capture();
}

void mouseReleased()
{
  float dist, dx, dy;
  dx = abs(mouseX - pbx);
  dy = abs(mouseY - pby);
  dist = sqrt(dx*dx + dy*dy);
  if(dist <= 75) capture();
  dx = abs(mouseX - sbx);
  dy = abs(mouseY - sby);
  dist = sqrt(dx*dx + dy*dy);
  if(dist <= 55) save();
}

void initPermissions(boolean granted)
{
  if(granted)
  {
    println("initPermissions called: granted.");
    havecamperm = true;
    startCameras();
  }
  else
  {
    println("initPermissions called: NOT granted.");
  }
}

private void makeDepthGraphics()
{
  int w, h, x, y, dep, dc, ind, dmin, dmax;
  color col;
  w = dcam.width;
  h = dcam.height;
  dmin = dcam.dmin;
  dmax = dcam.dmax;
  println("Depth: "+dmin+" --> "+dmax);
  dgraphic=createGraphics(w,h);
  dgraphic.beginDraw();
  dgraphic.loadPixels();
  for(y=0;y<h;y++)
  {
    for(x=0;x<w;x++)
    {
      ind=(y*w)+x;
      dep = dcam.depth[ind];
      if(dep < 10 || dcam.conf[ind] < 8)
      {
        col = color(255, 0, 0);
      }
      else
      {
        dc = (int) map(constrain((float)dep,(float)dmin,(float)dmax),(float)dmin,(float)dmax,255f,0f);
        col = color(dc,dc,dc);
      }
      
      dgraphic.pixels[(y*w)+x] = col;
    }
  }
  dgraphic.updatePixels();
  dgraphic.endDraw();
}

