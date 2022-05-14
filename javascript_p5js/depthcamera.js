var dcam, cloud;
var xrot = 0, yrot = 0;
var df, cam, camdist=0;
var minconfidence = 10, oldminconf=-1, numinconf=0;
var confslider;

function preload()
{
  df = loadBytes("./javascript_p5js/rubiks.dcam");
}

function setup()
{
  const urlParams = new URLSearchParams(window.location.search);
  const doembed = urlParams.get('embed');
  if(doembed==null)
  {
    document.getElementById("header").style.display = "block";
    document.getElementById("extratext").style.display = "block";
    document.getElementById("footer").style.display = "block";
  }
  document.getElementById("loading").style.display = "none";
  document.getElementById("view3d").style.display = "block";
  var cv = createCanvas(640, 480, WEBGL);
  cv.parent("canvas3d");
  confslider=createSlider(0, 100, minconfidence, 1);
  confslider.parent("confslider");
  confslider.style('width', '620px');
  dcam = new DepthLoader();
  dcam.loadFromBytes(df.bytes);
  console.log("Depth: "+dcam.dmin+" --> "+dcam.dmax);
  console.log("Sensor: "+dcam.sensorwidth+" x "+dcam.sensorheight+" (fl = "+dcam.focallength+")");
  console.log("YPR: "+dcam.yaw+", "+dcam.pitch+", "+dcam.roll);
  cloud = new DepthCloud(dcam);
  cloud.decimate(4);
  cloud.minConf = 0;
  cloud.startX = 100;
  cloud.endX = dcam.dwidth - 100;
  cloud.startY = 50;
  cloud.endY = dcam.dheight - 50;
  cloud.maxDepth = 1500;
  cloud.makeDepthCloud();
  cloud.correctRollPitch();
  cloud.rotateX(-PI/2); // Top down view
  cloud.centreX();
  cloud.centreY();
  cloud.fromZeroZ();
  console.log("Points created: "+cloud.vertices.length);
  console.log("X: "+cloud.minX+" -> "+cloud.maxX);
  console.log("Y: "+cloud.minY+" -> "+cloud.maxY);
  console.log("Z: "+cloud.minZ+" -> "+cloud.maxZ);
  cam = createCamera();
  cam.perspective(PI/2, width/height, 0.01, -cloud.maxZ);
  // We can calculate the camera distance easily because FOV is 90 degrees (i.e. PI/2)
  camdist = max(abs(cloud.minX),abs(cloud.maxX),abs(cloud.minY),abs(cloud.maxY))*0.5;
}

function draw()
{
  minconfidence = confslider.value();
  background(209,252,240);
  cam.camera(0,0,camdist,0,0,0,0,1,0);
  cam.lookAt(0,0,0);
  //noLights();
  //lights();
  //ambientLight(50, 50, 50);
  rotateY(yrot);
  rotateX(xrot);
  drawshape();
  if(minconfidence !== oldminconf)
  {
    document.getElementById("confvalue").innerHTML = minconfidence;
    document.getElementById("numverts").innerHTML = numinconf;
    oldminconf = minconfidence;
  }
}

function drawshape()
{
  // beginShape(POINTS) in P5.js won't allow us to change the colour
  // per vertex, so we use point(x,y,z) with a decimated mesh instead.
  // Probably we would need to use something like three.js and a vertex
  // buffer object to display the full mesh until P5.js fixes it.
  var c, r=0, g=0, b=0;
  numinconf = 0;
  strokeWeight(1);
  for(c=0; c<cloud.vertices.length; c++)
  {
    if(cloud.confidence[c] >= minconfidence)
    {
      r=map(cloud.confidence[c],cloud.minConf,cloud.maxConf,0,255);
      g = 0;
      b = 255 - r;
      noFill();
      stroke(r,g,b);
      point(cloud.vertices[c][0],cloud.vertices[c][1],-cloud.vertices[c][2]);
      numinconf++;
    }
  }
}

function mouseDragged()
{
  if(mouseX>=0 && mouseX<width && mouseY>=0 && mouseY<height)
  {
    xrot = map(mouseY, 0, height, PI/2, -PI/2);
    yrot = map(mouseX, 0, width, -PI/2, PI/2);
  }
}

function keyReleased()
{
  switch(key)
  {
    case '-':   camdist*=1.1; break;
    case '+':   if(camdist>0) camdist*=0.9; break;
  }
}
