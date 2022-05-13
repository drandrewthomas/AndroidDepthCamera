# Using Depth Camera Data With Javascript and P5.js

The files here are a simple example of how to use depth camera files, created using the APDE code, in a web page. It includes Javascript classes for loading data (and the metadata) from an array of bytes, and for converting the depth values to a point cloud using the camera sensor metadata. It's based on P5.js, so as to make it easy to use and as an example of using the depth data in a Processing-like web environment. However, the classes are pure Javascript so you could use them without P5.js too. When you run the code you'll get a slider that allows you to explore the effects of depth-confidence and you can drag the cloud to change the view.

Here's a screenshot of the point cloud in the example, which is of a Rubiks Cube imaged from above. [Click here to view it live on Github.io](https://drandrewthomas.github.io/AndroidDepthCamera/).

![Screenshot of a point cloud in the p5.js web page](./dcamp5js.png)

**Note 1:** To make life easier for displaying the example on github.io, the index.html file for it is in the root folder of this repository. So if you download or fork the code, you need the root index.html in a folder that also contains this 'javascript-p5js' folder.

**Note 2:** There seems to be a bug in P5.js in that beginShape(POINTS) won't allow us to change the colour per vertex, which works in the desktop version of Processing. For that reason the example uses point(x,y,z), instead of vertex(x,y,z) in beginShape()/endShape(). That's much slower in drawing, so the example decimates the point cloud. Probably we would need to use something like three.js and a vertex buffer object to display the full cloud. Or, of course, maybe P5.js will fix that bug so we can improve the example.

## Credits

This project is copyright 2021-2022 Andrew Thomas and is distributed under the GPL3 license.
