public class tofloader
{

  public int[] depth, conf;
  public int averages, dwidth, dheight;
  public float yaw, pitch, roll, sensorwidth, sensorheight, focallength;
  public boolean gotframe = false;
  public int dmin = 0, dmax = 0;
  public int year, month, day, hours, minutes, seconds, ms4;
  private String[] mths = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

  public tofloader()
  {
  }

  public byte[] makeFileBytes()
  {
    return makeFileBytes(0);
  }
  
  public byte[] makeFileBytes(int extra)
  {
    int c, ind, oy, op, or, sw, sh, fl;
    byte[] df = {0};
    if(!gotframe) return df;
    int headerlen = 30;
    int ftver = 1;
    int numb = headerlen + (dwidth * dheight * 3) + extra;
    df = new byte[numb];
    df[0] = (byte) 'D';
    df[1] = (byte) 'C';
    df[2] = (byte) 'A';
    df[3] = (byte) 'M';
    df[4] = (byte) ftver; // File type version
    df[5] = (byte) headerlen; // Max 255 bytes!
    df[6] = (byte) ((dwidth >> 8) & 0xFF);
    df[7] = (byte) (dwidth & 0xFF);
    df[8] = (byte) ((dheight >> 8) & 0xFF);
    df[9] = (byte) (dheight & 0xFF);
    df[10] = (byte) averages; // Number of averages for depth
    oy = (int) (yaw * 100);
    if(oy < 0) oy = (360 * 100) + oy;
    op = (int) (pitch * 100);
    if(op < 0) op = (360 * 100) + op;
    or = (int) (roll * 100);
    if(or < 0) or = (360 * 100) + or;
    df[11] = (byte) ((oy >> 8) & 0xFF);
    df[12] = (byte) (oy & 0xFF);
    df[13] = (byte) ((op >> 8) & 0xFF);
    df[14] = (byte) (op & 0xFF);
    df[15] = (byte) ((or >> 8) & 0xFF);
    df[16] = (byte) (or & 0xFF);
    sw = (int) (sensorwidth * 100);
    sh = (int) (sensorheight * 100);
    fl = (int) (focallength * 100);
    df[17] = (byte) ((sw >> 8) & 0xFF);
    df[18] = (byte) (sw & 0xFF);
    df[19] = (byte) ((sh >> 8) & 0xFF);
    df[20] = (byte) (sh & 0xFF);
    df[21] = (byte) ((fl >> 8) & 0xFF);
    df[22] = (byte) (fl & 0xFF);
    for(c=23; c<headerlen; c++) df[c] = 0;
    ind = headerlen;
    for(c=0; c<(dwidth*dheight); c++)
    {
      df[ind + 0] = (byte) ((depth[c] >> 8) & 0xFF);
      df[ind + 1] = (byte) (depth[c] & 0xFF);
      ind+=2;
    }
    for(c=0; c<(dwidth*dheight); c++)
    {
      df[ind] = (byte) conf[c];
      ind++;
    }
    return df;
  }
  
  public boolean loadFromBytes(byte[] data)
  {
    int c, ftv, hl, el, w, h, nta, numd, ind;
    String fid = "";
    if(data.length<30) return false;
    for(c=0; c<4; c++) fid += (char) data[c];
    if(!fid.equals("DCAM")) return false;
    ftv = b2i(data[4]);
    hl = b2i(data[5]);
    w = (b2i(data[6])*256) + b2i(data[7]);
    h = (b2i(data[8])*256) + b2i(data[9]);
    nta = b2i(data[10]);
    if(nta!=1 && nta!=2 && nta!=4 && nta!=8) return false;
    el = hl + (w*h*3);
    if(data.length<el) return false;
    numd = w * h;
    depth = new int[numd];
    conf = new int[numd];
    dwidth = w;
    dheight = h;
    averages = nta;
    yaw = ((b2i(data[11])*256) + b2i(data[12]))/100;
    if(yaw>180) yaw-=360;
    pitch = ((b2i(data[13])*256) + b2i(data[14]))/100;
    if(pitch>180) pitch-=360;
    roll = ((b2i(data[15])*256) + b2i(data[16]))/100;
    if(roll>180) roll-=360;
    sensorwidth = ((b2i(data[17])*256) + b2i(data[18]))/100;
    sensorheight = ((b2i(data[19])*256) + b2i(data[20]))/100;
    focallength = ((b2i(data[21])*256) + b2i(data[22]))/100;
    dmin = 999999;
    dmax = -999999;
    for(c=0; c<numd; c++)
    {
      ind = hl + (c*2);
      depth[c] = (b2i(data[ind])*256) + b2i(data[ind+1]);
      if (depth[c] < dmin && depth[c] > 10) dmin = depth[c];
      if (depth[c] > dmax) dmax = depth[c];
    }
    for(c=0; c<numd; c++)
    {
      ind = hl + (numd * 2) + c;
      conf[c] = b2i(data[ind]);
    }
    gotframe = true;
    return true;
  }
  
  private int b2i(byte b)
  {
    return (b<0 ? 256+b:b);
  }
  
}
