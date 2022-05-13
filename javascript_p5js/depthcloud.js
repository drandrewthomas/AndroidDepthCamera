class DepthCloud
{

  constructor(dcd)
  {
    this.dc = dcd;
    this.vertices=[];
    this.confidence=[];
    this.minDepth = 10;
    this.maxDepth = 100000;
    this.minConf = 10;
    this.maxConf = 100;
    this.minX=0;
    this.maxX=0;
    this.minY=0;
    this.maxY=0;
    this.minZ=0;
    this.maxZ=0;
    this.sizeX=0;
    this.sizeY=0;
    this.sizeZ=0;
    this.midX=0;
    this.midY=0;
    this.midZ=0;
    this.startX=0;
    this.endX=this.dc.dwidth - 1;
    this.startY=0;
    this.endY=this.dc.dheight - 1;
    this.stepX = 1;
    this.stepY = 1;
  }

  makeDepthCloud()
  {
    var x, y, dep, conf, ind;
    var wmm = this.dc.sensorwidth;
    var hmm = this.dc.sensorheight;
    var fl = this.dc.focallength;
    var wpx = this.dc.dwidth;
    var hpx = this.dc.dheight;
    var xmmpx = wmm/wpx;
    var ymmpx = hmm/hpx;
    this.vertices = [];
    this.confidence = [];
    for(x=this.startX; x<=this.endX; x+=this.stepX)
    {
      for(y=this.startY; y<=this.endY; y+=this.stepY)
      {
        ind = (y * wpx) + x;
        dep = this.dc.depth[ind];
        conf = this.dc.confidence[ind];
        if(dep>=this.minDepth && dep<=this.maxDepth)
        {
          if(conf>=this.minConf && conf<=this.maxConf)
          {
            this.vertices.push([(dep/fl)*(x-(wpx/2))*xmmpx, (dep/fl)*(y-(hpx/2))*ymmpx, dep]);
            this.confidence.push(conf);
          }
        }
      }
    }
    this.updateDimensions();
  }

  decimate(stp)
  {
    if(stp==1 || stp==2 || stp==4 || stp==8 || stp==16)
    {
      this.stepX = stp;
      this.stepY = stp;
    }
  }
  
  translate(xt, yt, zt)
  {
    var c;
    for(c=0; c<this.vertices.length; c++)
    {
      this.vertices[c][0]+=xt;
      this.vertices[c][1]+=yt;
      this.vertices[c][2]+=zt;
    }
    this.updateDimensions();
  }

  scale(xs, ys, zs)
  {
    var c;
    for(c=0; c<this.vertices.length; c++)
    {
      this.vertices[c][0]*=xs;
      this.vertices[c][1]*=ys;
      this.vertices[c][2]*=zs;
    }
    this.updateDimensions();
  }
  
  correctYaw()
  {
    this.rotateYDegrees(-this.dc.yaw);
  }

  correctRollPitch()
  {
    this.correctRoll();
    this.correctPitch();
  }

  correctRoll()
  {
    this.rotateZDegrees(-(this.dc.roll+90));
  }

  correctPitch()
  {
    this.rotateXDegrees(this.dc.pitch);
  }
  
  rotateXDegrees(ang)
  {
    var xr=ang*(Math.PI/180);
    this.rotateX(xr);
  }

  rotateYDegrees(ang)
  {
    var yr=ang*(Math.PI/180);
    this.rotateY(yr);
  }

  rotateZDegrees(ang)
  {
    var zr=ang*(Math.PI/180);
    this.rotateZ(zr);
  }
  
  rotateX(xr)
  {
    var c, sdist, sang;
    for(c=0; c<this.vertices.length; c++)
    {
      // Rotate YZ plane around X axis
      if(xr!=0)
      {
        sdist = this.mag2d(this.vertices[c][1],this.vertices[c][2]);
        sang = this.getangle(this.vertices[c][1],this.vertices[c][2])+xr;
        this.vertices[c][1] = sdist*Math.sin(sang);
        this.vertices[c][2] = sdist*Math.cos(sang);
      }
    }
    this.updateDimensions();
  }
  
  rotateY(yr)
  {
    var c, sdist, sang;
    for(c=0; c<this.vertices.length; c++)
    {
      // Rotate XZ plane around Y axis
      if(yr!=0)
      {
        sdist=this.mag2d(this.vertices[c][0],this.vertices[c][2]);
        sang=this.getangle(this.vertices[c][0],this.vertices[c][2])+yr;
        this.vertices[c][0]=sdist*Math.sin(sang);
        this.vertices[c][2]=sdist*Math.cos(sang);
      }
    }
    this.updateDimensions();
  }
  
  rotateZ(zr)
  {
    var c, sdist, sang;
    for(c=0; c<this.vertices.length; c++)
    {
      // Rotate XY plane around Z axis
      if(zr!=0)
      {
        sdist=this.mag2d(this.vertices[c][0],this.vertices[c][1]);
        sang=this.getangle(this.vertices[c][0],this.vertices[c][1])+zr;
        this.vertices[c][0]=sdist*Math.sin(sang);
        this.vertices[c][1]=sdist*Math.cos(sang);
      }
    }
    this.updateDimensions();
  }
  
  convertToZUp()
  {
    var c, tmp;
    for(c=0; c<this.vertices.length; c++)
    {
      tmp=this.vertices[c][1];
      this.vertices[c][1]=this.vertices[c][2];
      this.vertices[c][2]=tmp;
    }
    this.updateDimensions();
  }
  
  updateDimensions()
  {
    var c;
    this.minX = 999999999;
    this.maxX = -999999999;
    this.minY = 999999999;
    this.maxY = -999999999;
    this.minZ = 999999999;
    this.maxZ = -999999999;
    for(c=0; c<this.vertices.length; c++)
    {
      if(this.vertices[c][0]<this.minX) this.minX = this.vertices[c][0];
      if(this.vertices[c][0]>this.maxX) this.maxX = this.vertices[c][0];
      if(this.vertices[c][1]<this.minY) this.minY = this.vertices[c][1];
      if(this.vertices[c][1]>this.maxY) this.maxY = this.vertices[c][1];
      if(this.vertices[c][2]<this.minZ) this.minZ = this.vertices[c][2];
      if(this.vertices[c][2]>this.maxZ) this.maxZ = this.vertices[c][2];
    }
    this.sizeX = this.maxX - this.minX;
    this.sizeY = this.maxY - this.minY;
    this.sizeZ = this.maxZ - this.minZ;
    this.midX = (this.maxX + this.minX) / 2;
    this.midY = (this.maxY + this.minY) / 2;
    this.midZ = (this.maxZ + this.minZ) / 2;
  }
  
  centre()
  {
    this.translate(-this.midX, -this.midY, -this.midZ);
  }
  
  centreX()
  {
    this.translate(-this.midX, 0, 0);
  }
  
  centreY()
  {
    this.translate(0, -this.midY, 0);
  }
  
  centreZ()
  {
    this.translate(0, 0, -this.midZ);
  }
  
  fromZeroZ()
  {
    this.translate(0, 0, -this.minZ);
  }
  
  land()
  {
    this.translate(0, -this.minY, 0);
  }
  
  bury()
  {
    this.translate(0, -this.maxY, 0);
  }
  
  // PRIVATE HELPER FUNCTIONS
            
  map(num, smin, smax, emin, emax)
  {
    return (((num-smin)/(smax-smin))*(emax-emin))+emin;
  }

  mag2d(a, b)
  {
    return Math.sqrt(a*a+b*b);
  }

  getangle(a, b)
  {
    var sang = 0;
    if(a===0 && b===0) return 0;
    if(b===0) sang=Math.atan(a/0.00000000001);
    else sang = Math.atan(a/b);
    if(sang<0) sang *= (-1);
    if(a>=0 && b>=0) return sang;
    if(a>=0 && b<=0) return (Math.PI-sang);
    if(a<=0 && b<=0) return (Math.PI+sang);
    if(a<=0 && b>=0) return ((2*Math.PI)-sang);
    return 0;
  }
  
}
