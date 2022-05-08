# DEPTH DATA GETTING

def get_depth_minmax(dfr,mindepth=1,maxdepth=999999,edgeoff=0):
    """
    Note that mindepth defaults to 1 because a
    zero value really means no depth was
    measured. So we get the min/max of only
    real measurements if mindepth>0.
    """
    dw=dfr[0]
    dh=dfr[1]
    dmin=999999999999
    dmax=-999999999999
    for y in range(edgeoff,dh-edgeoff):
        for x in range(edgeoff,dw-edgeoff):
            ind=(y*dw)+x
            v=dfr[2][ind]
            if v>=mindepth and v<=maxdepth:
                if v<dmin: dmin=v
                if v>dmax: dmax=v
    return [dmin,dmax]

def get_horiz_depth_slice(dfr,y,zero=0):
    dw=dfr[0]
    dh=dfr[1]
    if y>=dh: return []
    sl=[]
    for x in range(0,dw):
        ind=(y*dw)+x
        v=dfr[2][ind]
        if v==0: sl.append(zero)
        else: sl.append(v)
    return sl

def get_vert_depth_slice(dfr,x,zero=0):
    dw=dfr[0]
    dh=dfr[1]
    if x>=dw: return False
    sl=[]
    for y in range(0,dh):
        ind=(y*dw)+x
        v=dfr[2][ind]
        if v==0: sl.append(zero)
        else: sl.append(v)
    return sl


# DEPTH ZEROING FUNCTIONS

def zero_depth_between(dfr,near_clip,far_clip,zero=0):
    for c in range(0,len(dfr[2])):
        if dfr[2][c]>=near_clip and dfr[2][c]<=far_clip:
            dfr[2][c]=zero
    return True

def zero_depth_outside(dfr,near_clip,far_clip,zero=0):
    for c in range(0,len(dfr[2])):
        if dfr[2][c]<near_clip or dfr[2][c]>far_clip:
            dfr[2][c]=zero
    return True

def zero_low_confidence(dfr,cfr,mincon,zero=0):
    if dfr[0]!=cfr[0] or dfr[1]!=cfr[1]:
        print("Error: Depth and confidence frames are different sizes!")
        return False
    for c in range(0,len(dfr[2])):
        if cfr[2][c]<mincon:
            dfr[2][c]=zero
    return True


# CONVERSIONS

def depth_frame_to_pointcloud(dfr, sensor,mindepth=1, maxdepth=999999, conf=None, minconf=0, maxconf=100, minx=-999999, maxx=999999, miny=-999999, maxy=999999, addxy=False, addcon=False):
    # Sensor [focal length mm, widht mm, height mm, pixel width, pixel height]
    fl=sensor[0]
    wmm=sensor[1]
    hmm=sensor[2]
    wpx=sensor[3]
    hpx=sensor[4]
    xmmpx=wmm/wpx
    ymmpx=hmm/hpx
    pcl=[]
    for x in range(0,dfr[0]):
        for y in range(0,dfr[1]):
            ind=(y*dfr[0])+x
            dep=dfr[2][ind]
            if dep>=mindepth and dep<=maxdepth:
                xp=(dep/fl)*(x-(dfr[0]/2))*xmmpx
                yp=(dep/fl)*(y-(dfr[1]/2))*ymmpx
                add = True
                if x<minx or x>maxx:
                    add=False
                if y<miny or y>maxy:
                    add=False
                if conf!=None:
                    dc=conf[2][ind]
                    if dc<minconf or dc>maxconf:
                        add=False
                if add:
                    pt=[xp,yp,dep]
                    if addcon:
                        if conf!=None:
                            pt.append(dc)
                    if addxy:
                        pt.append(x)
                        pt.append(y)
                    pcl.append(pt)
    return pcl
