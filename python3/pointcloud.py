import sys
import numpy as np
from depthcamera import loader as ldr
from depthcamera import depthframe as dfm
from matplotlib import pyplot as plt

# Get a frame from the server
ok=ldr.load_file("leaves.dcam")
if not ok:
    print("Oh dear, something went wrong!")
    sys.exit()
# Get the depth data
dep=ldr.get_depth()
# Get the depth confidence data
con=ldr.get_depth_confidence()
# Get the camera sensor data
sen=ldr.get_sensor()
# Make a point cloud
pcl=dfm.depth_frame_to_pointcloud(dep, sen,mindepth=100, maxdepth=270, conf=con, minconf=20, maxconf=100, minx=150, maxx=540, miny=50, maxy=430, addcon=True)
# Make XYZ and confidence data array
xyz=np.array(pcl)
# Plot a 3D scatter graph
# To colour by depth confidence change
# c=xyz[:,2] to xyz[:,3]
fig = plt.figure(figsize=(12,7))
ax = fig.add_subplot(projection='3d')
img = ax.scatter(xyz[:,0], xyz[:,1], xyz[:,2], c=xyz[:,2], cmap=plt.jet())
fig.colorbar(img)
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_zlabel('Z')
plt.show()
