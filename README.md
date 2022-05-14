# Android Depth Camera Experiments

A couple of years ago I played with using an Intel Realsense camera on Android, coding to let me get the depth data into APDE and PyDroid3. That was fun, and quite successful, but it did mean having to attach the camera and a long USB cable to the phone. So I decided to buy a phone with a Time-of-Flight depth camera, to try out a more elegant and compact solution. That led to the experiments in this repository, which include APDE (like Processing for Android) code to capture depth data, as well as code in Processing, Python 3, Javascript and P5.js to work on the data saved in the APDE code.

So while searching for information on how to access the depth camera data stream I came across the work of Luke Ma who had written some Java code to do that on a Samsung S10 ([click here to visit his Github page](https://github.com/plluke/tof)). After some fiddling with the code to work on my Samsung S20 I had the starting point of a simple app running in AIDE on my phone. I then added many improvements that should allow the code to work with all Android phones that have a depth camera that works with Google's Camera2 API (although it has not been tested on all those devices).

I then adapted the code to allow it to get single frames of data, to average depth and depth-confidence over a few frames to reduce noise, to make finding the depth camera object easier, and to obtain camera metadata needed to create point clouds from the data. But, I wasn't happy just having an app, I wanted a more maker-friendly project, so I wondered if it would be possible to port the camera class to APDE, as an easy way of using it in a Processing for Android environment. It turned out not to be very straightforward, but soon I learnt about Loopers and how to give the camera a thread to send messages on. And so the experiments here were born.

Also, for a maker-friendly project I wanted to be able to use data saved in APDE in other programming languages. So I ported code I'd previously used with my Realsense camera, which allow loading and viewing of depth and depth-confidence data. So library files and examples are included here in Processing, Python 3 (written using PyDroid3 on my Android phone) and Javascript. The Javascript example is also based on P5.js, thereby extending the range of Processing-based options for using the data, and was written using the excellent repl.it platform.

## Examples of Depth Camera Data

Below are some examples of depth data captured using the code included here. Clockwise from top left we have a soda can, a small pine cone, a UK one pound coin and a lifebouy case fixed on a wall. The red areas denote pixels where the sensor returned zero depth, which basically means it failed to get a measurement. The images show a wide range of object sizes, and even the small UK coin has some surface detail if you look closely.

![Examples of Depth Camera captures](./dcamgrid.jpg)

## Camera Metadata

As well as the depth and depth-confidence values, the APDE code also gets metadata. Those metadata include:

* Pixel size as width and height.
* Number of averages used.
* Orientation as yaw, pitch and roll (degrees).
* Sensor physical details as width, height and focal length ( all in mm)

## What's included?

There are four folders here, each containing code and examples for different systems and uses. They are:

* **APDE code:** This is the main Android code for accessing a Camera2 depth camera. It is provided in the form of a basic camera app that can save data files for use in the other code examples. It handles things like the Android camera permissions so should be a useful base for your own code. However, note that the camera code is really a Java file, so it should also give a good starting point for Android Studio and AIDE projects.

* **Processing PC code:** This code provides classes for loading data, and metadata, from a file saved in the APDE app, as well as for converting those data into pointclouds with x, y and z vertices (plus an array of indexed depth-confidence values). The classes are provided within an example sketch that loads an example file and displays a point cloud of the data. You can also use the loader class from the PC code in APDE, as a simple way to load files without worrying about all the camera permissions.

* **Python 3 code:** This code provides a means of loading depth, and depth-confidence data, together with the camera metadata, plus code for making images of those data and even making point clouds. It is provided with some examples, including code to load data and view images and sections with matplotlib. Another example also uses matplotlib, but to display a point cloud in 3D. Note that the code was mostly written and tested in PyDroid3, so should be easy to use on a PC or Android device.

* **Javascript code:** This is basically a simple port of the Processing PC code, with the loading and point cloud generation code changed to Javascript classes. It is provided within an example web-page that displays a point cloud, coloured using the depth-confidence values, that you can rotate by dragging over it. It also allows you to change the minimum depth-confidence value to explore how that relates to the quality of depth data. [Click here to view it live on Github.io](https://drandrewthomas.github.io/AndroidDepthCamera/).

## Credits

Some code is based on the example code kindly provided by Luke Ma for which I give great thanks and kudos. [Please vist his repository](https://github.com/plluke/tof).

This project is copyright 2021-2022 Andrew Thomas and is distributed under the GPL3 license.
