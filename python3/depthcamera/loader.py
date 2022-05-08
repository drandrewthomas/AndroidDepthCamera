fbytes = None
header = None

def load_file(fname):
    global fbytes
    with open(fname, "rb") as f:
        fbytes=f.read()
    ok=check_dcam()
    return ok

def check_dcam():
    global header
    header=[]
    flen=len(fbytes)
    if flen<30:
        print("Error: Very short file length!")
        return False
    fid=""
    for c in range(0,4): fid=fid+chr(fbytes[c])
    if fid!="DCAM": return False
    headerlen=fbytes[5]
    dw = (fbytes[6]*256) + fbytes[7]
    dh = (fbytes[8]*256) + fbytes[9]
    nta = fbytes[10]
    if nta!=1 and nta!=2 and nta!=4 and nta!=8:
        print("Error: Wrong number of averages value!")
        return False
    explen = headerlen + (dw*dh*3)
    if flen<explen:
        print("Error: Expected "+str(explen)+" bytes but found "+str(flen)+"!")
        return False
    for c in range(0,headerlen):
        header.append(fbytes[c])
    return True

def get_file_version():
    return header[4]

def get_header_length():
    return header[5]

def get_depth_width():
    return (header[6]*256) + header[7]

def get_depth_height():
    return (header[8]*256) + header[9]

def get_depth_averages():
    return header[10]

def get_sensor():
    # Sensor [focal length mm, widht mm, height mm, pixel width, pixel height]
    fl=get_focal_length()
    wmm=get_sensor_width()
    hmm=get_sensor_height()
    wpx=get_depth_width()
    hpx=get_depth_height()
    return [fl,wmm,hmm,wpx,hpx]

def get_sensor_width():
    # Should be mm
    return ((header[17]*256) + header[18])/100

def get_sensor_height():
    # Should be mm
    return ((header[19]*256) + header[20])/100

def get_focal_length():
    # Should be mm
    return ((header[21]*256) + header[22])/100

def get_orientation():
    # Values are in degrees
    yaw = ((header[11]*256) + header[12])/100
    if yaw>180: yaw = yaw-360
    pitch = ((header[13]*256) + header[14])/100
    if pitch>180: pitch = pitch-360
    roll = ((header[15]*256) + header[16])/100
    if roll>180: roll = roll-360
    return [yaw,pitch,roll]

def get_depth():
    hl = get_header_length()
    w = get_depth_width()
    h = get_depth_height()
    dfr=[w,h,[]]
    nd=w*h
    for c in range(0,nd):
        ind = hl + (c*2)
        dfr[2].append((fbytes[ind]*256)+fbytes[ind+1])
    return dfr

def get_depth_confidence():
    hl = get_header_length()
    w = get_depth_width()
    h = get_depth_height()
    confr=[w,h,[]]
    nd=w*h
    for c in range(0,nd):
        ind = hl + (nd * 2) + c
        confr[2].append(fbytes[ind])
    return confr
