from PIL import Image, ImageDraw

def make_depth_image(dfr, mindepth=1, maxdepth=100000, lowrgb=[255,0,0]):
    w=dfr[0]
    h=dfr[1]
    im=Image.new("RGBA",(w,h),(255,255,255,255))
    dpix=im.load()
    for yc in range(0,h):
        for xc in range(0,w):
            ind=(yc*w)+xc
            dp=dfr[2][ind]
            if dp<mindepth or dp>maxdepth:
                r= lowrgb[0]
                g=lowrgb[1]
                b=lowrgb[2]
            else:
                r=255-int(((dp-mindepth)/(maxdepth-mindepth))*255)
                g=r
                b=r
            dpix[xc,yc]=(r,g,b,255)
    return im

def make_confidence_image(conf, minconf=1, lowrgb=[255,0,0]):
    w=conf[0]
    h=conf[1]
    im=Image.new("RGBA",(w,h),(255,255,255,255))
    dpix=im.load()
    for yc in range(0,h):
        for xc in range(0,w):
            ind=(yc*w)+xc
            con=conf[2][ind]
            if con<minconf:
                r=lowrgb[0]
                g=lowrgb[1]
                b=lowrgb[2]
            else:
                r=int((con/100)*255)
                g=r
                b=r
            dpix[xc,yc]=(r,g,b,255)
    return im

def thumbnail(im, w, h):
    tim=im.copy()
    tim.thumbnail((w, h), Image.BICUBIC)
    return tim

def checkerboard(nx, ny, chw, chh, back=[255,255,255], fill=[0,0,0]):
    x0=0
    y0=0
    dims=0
    b=(back[0],back[1],back[2],255)
    f=(fill[0],fill[1],fill[2],255)
    chkb=Image.new("RGBA",(nx*chw,ny*chh),b)
    pix=ImageDraw.Draw(chkb)
    for y in range(0,ny):
        y0=y*chh
        if y%2==1:
            for x in range(0,nx,2):
                x0=x*chw
                dims=((x0,y0),(x0+chw,y0+chh))
                pix.rectangle(dims,fill=f)
        else:
            for x in range(1,nx,2):
                x0=x*chw
                dims=((x0,y0),(x0+chw,y0+chh))
                pix.rectangle(dims,fill=f)
    return chkb

def save_image(im, fname, quality=0,subsamp=0):
    im.save(fname,compress_level=quality,subsampling=subsamp)

