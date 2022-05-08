# Using Depth Camera data in Python 3 and PyDroid3

Here you will find a simple Python 3 library, with examples, for loading and using depth camera data saved into files using the Android APDE code. All of it was written in Python3 using PyDroid3 on an Android device, so you can use the code on a PC or an Android tablet. You can even run it on a Chromebook, either using Python 3 in a Linux container, or using the PyDriod3 Android app.

## A 2D data loading and plotting example

The dcamtest.py file loads an example depth image file of some leaves. It shows how to use the loader code to load a depth file, the depth frame code to get data, and the image maker code to create depth and depth-confidence graphics. The example uses those things to create a matplotlib plot showing the depth and depth-confidence data along with some horizontal sections through the depth data. Here's a screenshot of the example plot using PyDroid3 on my Chromebook.

![Screenshot of plotted 2D data in PyDroid3](./dcamtest.png)

**Note:** The example depth image shows an issue you should be aware of when using Android depth cameras: The depth data on the left approaches zero on the edge, whereas in real-life there was no close object there. The depth camera can be confused by bright sunlight, which was coming from the left, and as you can see those data even show a high depth-confidence value!

## A 3D data loading and plotting example

The pointcloud.py file loads the leaves depth image and converts it to a point cloud, using the metadata for the camera sensor the APDE code provided. The cloud is then plotted in 3D using matplotlib, which together with numpy is a prerequisite you need to install with pip. The code also illustrates how to create the point cloud as a trimmed version of the depth data, which allows you to ignore poor quality data around the edges and remove points too far away. Here's a screenshot of the example plot using PyDroid3 on my Chromebook.

![Screenshot of plotted 2D data in PyDroid3](./pointcloud.png)

**Note:**  The point cloud example uses matplotlib with a very large number of 3D vertices, so may update very slowly, especially on most Android devices, if you drag to change the plot view.
