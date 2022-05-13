class DepthLoader
{

  constructor()
  {
    this.depth=[];
    this.confidence=[];
    this.averages=0;
    this.dwidth=0;
    this.dheight=0;
    this.yaw=0;
    this.pitch=0;
    this.roll=0;
    this.sensorwidth=0;
    this.sensorheight=0;
    this.focallength=0;
    this.gotframe = false;
    this.dmin = 0;
    this.dmax = 0;
  }
  
  loadFromBytes(data)
  {
    var c, ftv, hl, el, w, h, nta, dep, numd, ind;
    var fid = "";
    if(data.length<30) return false;
    for(c=0; c<4; c++) fid += String.fromCharCode(data[c]);
    if(!fid==="DCAM") return false;
    ftv = data[4];
    hl = data[5];
    w = (data[6]*256) + data[7];
    h = (data[8]*256) + data[9];
    nta = data[10];
    if(nta!=1 && nta!=2 && nta!=4 && nta!=8) return false;
    el = hl + (w*h*3);
    if(data.length<el) return false;
    numd = w * h;
    this.depth = [];
    this.confidence = [];
    this.dwidth = w;
    this.dheight = h;
    this.averages = nta;
    this.yaw = ((data[11]*256) + data[12])/100;
    if(this.yaw>180) this.yaw-=360;
    this.pitch = ((data[13]*256) + data[14])/100;
    if(this.pitch>180) this.pitch-=360;
    this.roll = ((data[15]*256) + data[16])/100;
    if(this.roll>180) this.roll-=360;
    this.sensorwidth = ((data[17]*256) + data[18])/100;
    this.sensorheight = ((data[19]*256) + data[20])/100;
    this.focallength = ((data[21]*256) + data[22])/100;
    this.dmin = 999999;
    this.dmax = -999999;
    for(c=0; c<numd; c++)
    {
      ind = hl + (c*2);
      dep = (data[ind]*256) + data[ind+1];
      this.depth.push(dep);
      if (dep < this.dmin && dep > 10) this.dmin = dep;
      if (dep > this.dmax) this.dmax = dep;
    }
    for(c=0; c<numd; c++)
    {
      ind = hl + (numd * 2) + c;
      this.confidence.push(data[ind]);
    }
    this.gotframe = true;
    return true;
  }

}
