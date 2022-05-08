public class DepthCloud
{
  
  public float[][] vertices;
  public float[] confidence;
  public float yaw, pitch, roll;
  public int minDepth = 10, maxDepth = 100000;
  public int minConf = 10, maxConf = 100;
  public float minX, maxX, minY, maxY, minZ, maxZ;
  public float sizeX, sizeY, sizeZ;
  public float midX, midY, midZ;
  public tofloader dc;
  public int startX, endX, startY, endY;
  
  public DepthCloud(tofloader dcd)
  {
    dc = dcd;
    startX = 0;
    endX = dcd.dwidth - 1;
    startY = 0;
    endY = dcd.dheight - 1;
  }
  
  public void makeDepthCloud()
  {
    int x, y, dep, conf, numd, iind, oind = 0;
    yaw = dc.yaw;
    pitch = dc.pitch;
    roll = dc.roll;
    float wmm = dc.sensorwidth;
    float hmm = dc.sensorheight;
    float fl = dc.focallength;
    int wpx = dc.dwidth;
    int hpx = dc.dheight;
    float xmmpx = wmm/wpx;
    float ymmpx = hmm/hpx;
    numd = countVertices();
    vertices = new float[numd][3];
    confidence = new float[numd];
    for(x=startX; x<=endX; x++)
    {
      for(y=startY; y<=endY; y++)
      {
        iind = (y * wpx) + x;
        dep = dc.depth[iind];
        conf = dc.conf[iind];
        if(dep>=minDepth && dep<=maxDepth)
        {
          if(conf>=minConf && conf<=maxConf)
          {
            vertices[oind][0] = (dep/fl)*(x-(wpx/2))*xmmpx;
            vertices[oind][1] = (dep/fl)*(y-(hpx/2))*ymmpx;
            vertices[oind][2] = dep;
            confidence[oind] = conf;
            oind++;
          }
        }
      }
    }
    updateDimensions();
  }
  
  private int countVertices()
  {
    int x, y, ind, dep, conf, num = 0;
    int wpx = dc.dwidth;
    int hpx = dc.dheight;
    for(x=startX; x<=endX; x++)
    {
      for(y=startY; y<=endY; y++)
      {
        ind = (y * wpx) + x;
        dep = dc.depth[ind];
        conf = dc.conf[ind];
        if(dep>=minDepth && dep<=maxDepth)
          if(conf>=minConf && conf<=maxConf)
            num++;
      }
    }
    return num;
  }
  
  public void translate(float xt,float yt,float zt)
  {
    int c;
    for(c=0; c<vertices.length; c++)
    {
      vertices[c][0]+=xt;
      vertices[c][1]+=yt;
      vertices[c][2]+=zt;
    }
    updateDimensions();
  }

  public void scale(float xs,float ys,float zs)
  {
    int c;
    for(c=0; c<vertices.length; c++)
    {
      vertices[c][0]*=xs;
      vertices[c][1]*=ys;
      vertices[c][2]*=zs;
    }
    updateDimensions();
  }
  
  public void correctYaw()
  {
    rotateYDegrees(-yaw);
  }

  public void correctRollPitch()
  {
    correctRoll();
    correctPitch();
  }

  public void correctRoll()
  {
    rotateZDegrees(-(roll+90));
  }

  public void correctPitch()
  {
    rotateXDegrees(pitch);
  }
  
  public void rotateXDegrees(float ang)
  {
    float xr=(float) (ang*(Math.PI/180));
    rotateX(xr);
  }

  public void rotateYDegrees(float ang)
  {
    float yr=(float) (ang*(Math.PI/180));
    rotateY(yr);
  }

  public void rotateZDegrees(float ang)
  {
    float zr=(float) (ang*(Math.PI/180));
    rotateZ(zr);
  }
  
  public void rotateX(float xr)
  {
    int c;
    float sdist, sang;
    for(c=0; c<vertices.length; c++)
    {
      // Rotate YZ plane around X axis
      if(xr!=0)
      {
        sdist = mag2d(vertices[c][1],vertices[c][2]);
        sang = getangle(vertices[c][1],vertices[c][2])+xr;
        vertices[c][1] = (float) (sdist*Math.sin(sang));
        vertices[c][2] = (float) (sdist*Math.cos(sang));
      }
    }
    updateDimensions();
  }
  
  public void rotateY(float yr)
  {
    int c;
    float sdist, sang;
    for(c=0; c<vertices.length; c++)
    {
      // Rotate XZ plane around Y axis
      if(yr!=0)
      {
        sdist=mag2d(vertices[c][0],vertices[c][2]);
        sang=getangle(vertices[c][0],vertices[c][2])+yr;
        vertices[c][0]=(float) (sdist*Math.sin(sang));
        vertices[c][2]=(float) (sdist*Math.cos(sang));
      }
    }
    updateDimensions();
  }
  
  public void rotateZ(float zr)
  {
    int c;
    float sdist, sang;
    for(c=0; c<vertices.length; c++)
    {
      // Rotate XY plane around Z axis
      if(zr!=0)
      {
        sdist=mag2d(vertices[c][0],vertices[c][1]);
        sang=getangle(vertices[c][0],vertices[c][1])+zr;
        vertices[c][0]=(float) (sdist*Math.sin(sang));
        vertices[c][1]=(float) (sdist*Math.cos(sang));
      }
    }
    updateDimensions();
  }
  
  public void convertToZUp()
  {
    int c;
    float tmp;
    for(c=0; c<vertices.length; c++)
    {
      tmp=vertices[c][1];
      vertices[c][1]=vertices[c][2];
      vertices[c][2]=tmp;
    }
    updateDimensions();
  }
  
  public void updateDimensions()
  {
    int c;
    minX = 999999999;
    maxX = -999999999;
    minY = minX;
    maxY = maxX;
    minZ = minX;
    maxZ = maxX;
    for(c=0; c<vertices.length; c++)
    {
      if(vertices[c][0]<minX) minX = vertices[c][0];
      if(vertices[c][0]>maxX) maxX = vertices[c][0];
      if(vertices[c][1]<minY) minY = vertices[c][1];
      if(vertices[c][1]>maxY) maxY = vertices[c][1];
      if(vertices[c][2]<minZ) minZ = vertices[c][2];
      if(vertices[c][2]>maxZ) maxZ = vertices[c][2];
    }
    sizeX = maxX - minX;
    sizeY = maxY - minY;
    sizeZ = maxZ - minZ;
    midX = (maxX + minX) / 2;
    midY = (maxY + minY) / 2;
    midZ = (maxZ + minZ) / 2;
  }
  
  public void centre()
  {
    translate(-midX, -midY, -midZ);
  }
  
  public void centreX()
  {
    translate(-midX, 0, 0);
  }
  
  public void centreY()
  {
    translate(0, -midY, 0);
  }
  
  public void centreZ()
  {
    translate(0, 0, -midZ);
  }
  
  public void land()
  {
    translate(0, -minY, 0);
  }
  
  public void bury()
  {
    translate(0, -maxY, 0);
  }
  
  // PRIVATE HELPER FUNCTIONS
            
  private float map(float num,float smin,float smax,float emin,float emax)
  {
    return (((num-smin)/(smax-smin))*(emax-emin))+emin;
  }

  private float mag2d(float a, float b)
  {
    return (float) Math.sqrt(a*a+b*b);
  }

  private float getangle(float a,float b)
  {
    double sang = 0;
    if(a==0 && b==0) return 0f;
    if(b==0) sang=Math.atan(a/0.00000000001);
    else sang = Math.atan(a/b);
    if(sang<0) sang *= (-1);
    if(a>=0 && b>=0) return (float) sang;
    if(a>=0 && b<=0) return (float) (Math.PI-sang);
    if(a<=0 && b<=0) return (float) (Math.PI+sang);
    if(a<=0 && b>=0) return (float) ((2*Math.PI)-sang);
    return 0f;
  }
  
}
