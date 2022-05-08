import sys
from depthcamera import loader as ldr
from depthcamera import imagemaker as imk
from depthcamera import depthframe as dfm
from matplotlib import pyplot as plt

# Get a frame from file
ok=ldr.load_file("leaves.dcam")
if not ok:
    print("Oh dear, something went wrong!")
    sys.exit()
# Create a pyplot figure
fig=plt.figure(figsize=(18,10))
# Get the frames we want images of
dfr=ldr.get_depth()
confr=ldr.get_depth_confidence()
# Work out the range we want for the depth image
sz=dfm.get_depth_minmax(dfr)
# Subplot 1 - Depth image
dim=imk.make_depth_image(dfr,mindepth=sz[0],maxdepth=sz[1])
fig.add_subplot(2,2,1)
plt.imshow(dim,cmap='gray',aspect='equal')
plt.title("Depth", fontsize=24)
# Subplot 2 - Depth confidence image
conim=imk.make_confidence_image(confr, 30)
fig.add_subplot(2,2,2)
plt.imshow(conim,cmap='gray',aspect='equal')
plt.title("Confidence > 30%", fontsize=24)
#Subplot 3 - Horizontal sections
dh=ldr.get_depth_height()
s1=dfm.get_horiz_depth_slice(dfr,int(dh/4),zero=None)
s2=dfm.get_horiz_depth_slice(dfr,int(dh/4)*2,zero=None)
s3=dfm.get_horiz_depth_slice(dfr,int(dh/4)*3,zero=None)
fig.add_subplot(2,1,2)
plt.plot(s1,label="Top")
plt.plot(s2,label="Middle")
plt.plot(s3,label="Bottom")
plt.xticks(fontsize=16)
plt.yticks(fontsize=16)
plt.legend(fontsize=20)
# Display the figure
plt.show()



