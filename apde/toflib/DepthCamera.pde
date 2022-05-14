import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;

import android.hardware.camera2.TotalCaptureResult;

import android.media.ImageReader;
import android.util.Range;
import android.util.Size;
import android.util.SizeF;
import android.view.Surface;

import java.nio.ShortBuffer;
import java.nio.FloatBuffer;
import java.util.Arrays;
import java.util.List;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import android.graphics.ImageFormat;
import android.media.Image;
import android.media.ImageReader;

import android.os.Handler;
import android.os.HandlerThread;


public class DepthCamera
{

  private int FPS_MIN = 20;
  private int FPS_MAX = 20;
  public int camnum, width, height;
  public int facing, camlevel;
  public float[] lensintrinsiccalibration = {0,0,0,0,0};
  public float[] lensposerotation = {0,0,0,0};
  public float[] lensposetranslation = {0,0,0};
  public float sensorwidth, sensorheight, focallength;
  public float yaw, pitch, roll;
  private Context context;
  private CameraManager cameraManager;
  private CameraDevice camdev;
  private ImageReader previewReader;
  private CaptureRequest.Builder previewBuilder;
  private CameraCaptureSession camsession;
  public int[] depth, conf;
  private String[] cameras;
  public boolean gotcamera = false, gotframe = false;
  public int dmin = 0, dmax = 0;
  private int frnum, divshift;
  public int numtoaverage = 1; // 1, 2, 4 or 8 only
  private int[] tdata, tcon;
  private int bpf; // Bytes per frame
  public int[][] depthsizes;
  private HandlerThread mBackgroundThread;
  private Handler mBackgroundHandler;
  public String devinfo, directory;
  public int year, month, day, hours, minutes, seconds, ms4;
  private String[] mths = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
  public boolean allowlimited = true;
  public boolean havedepthcamera = false;

  public DepthCamera(Context ctx)
  {
    context=ctx;
    devinfo = android.os.Build.BRAND + " ";
    devinfo += android.os.Build.MODEL;
    devinfo = devinfo.substring(0, 1).toUpperCase() + devinfo.substring(1);
    directory = context.getExternalFilesDir(null).getAbsolutePath();
    cameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
    try
    {
      cameras = cameraManager.getCameraIdList();
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
    havedepthcamera = gotDepthCamera();
  }

  public void print()
  {
    if(!havedepthcamera)
    {
      System.out.println("No depth camera found!");
      return;
    }
    System.out.println("");
    System.out.println("Depth camera: #"+camnum);
    System.out.println("Facing: "+getLensFacingName());
    System.out.println("Image size: "+width+" x "+height);
    System.out.println("Sensor size: "+sensorwidth+" x "+sensorheight);
    System.out.println("Focal length: "+focallength);
    System.out.println("Level: "+getCameraLevelName());
    System.out.println("Calibration: "+floatsToString(lensintrinsiccalibration));
    System.out.println("Pose rotation: "+floatsToString(poseToAxes(lensposerotation)));
    System.out.println("Pose translation: "+floatsToString(lensposetranslation));
    System.out.println("");
  }

  public void capture()
  {
    capture(0, 0, 0);
  }

  public void capture(float y, float p, float r)
  {
    System.out.println("ToF capture requested.");
    gotframe = false;
    frnum = 0;
    if (numtoaverage < 1) numtoaverage = 1;
    if (numtoaverage > 8) numtoaverage = 8;
    int[] nta = {1, 1, 2, 2, 4, 4, 4, 4, 8}; // First 1 not used
    numtoaverage = nta[numtoaverage];
    int[] dsh = {0, 0, 1, 1, 2, 2, 2, 2, 3}; // First 0 not used
    divshift = dsh[numtoaverage];
    getCameraInfo(camnum);
    setDateTime();
    yaw = y;
    pitch = p;
    roll = r;
    try
    {
      camsession.capture(previewBuilder.build(), ToFCaptureCallback, mBackgroundHandler);
    }
    catch(CameraAccessException e)
    {
      e.printStackTrace();
    }
  }

  public boolean begin()
  {
    if(havedepthcamera)
    {
      startBackgroundThread();
      int dc = findDepthCamera();
      getCameraInfo(dc);
      int[] dsz = getLargestDepthSize(dc);
      dcam.open(dc,dsz[0],dsz[1]);
      return true;
    }
    else
    {
      return false;
    }
  }

  public void open(int cnum, int wid, int hgt)
  {
    gotcamera = false;
    camnum = cnum;
    width = wid;
    height = hgt;
    try
    {
      previewReader = ImageReader.newInstance(width, height, ImageFormat.DEPTH16, 1);
      ImageReader.OnImageAvailableListener readerListener = new ImageReader.OnImageAvailableListener()
      {
        @Override
        public void onImageAvailable(ImageReader reader)
        {
          System.out.println("onImageAvailable");
          mBackgroundHandler.post(new ToFImageMaker(reader.acquireNextImage()));
        }
      };
      previewReader.setOnImageAvailableListener(readerListener, mBackgroundHandler);
      cameraManager.openCamera(cameras[camnum], mStateCallback, mBackgroundHandler);
    }
    catch(Exception e)
    {
      System.out.println("Opening Camera has an exception: " + e);
      return;
    }
    gotcamera = true;
  }

  private void close()
  {
    camsession.close();
    stopBackgroundThread();
    camdev.close();
    camdev = null;
  }

  public void setDateTime()
  {
    Calendar calendar = Calendar.getInstance();
    day = calendar.get(Calendar.DATE);
    month = calendar.get(Calendar.MONTH);
    year = calendar.get(Calendar.YEAR);
    hours = calendar.get(Calendar.HOUR_OF_DAY);
    minutes = calendar.get(Calendar.MINUTE);
    seconds = calendar.get(Calendar.SECOND);
    ms4 = calendar.get(Calendar.MILLISECOND) / 4;
  }
  
  public String getExternalDirectoryName()
  {
    return directory;
  }
  
  public String getDateFolderName()
  {
    return day + mths[month] + year;
  }
  
  public String getDateFileName()
  {
    return getDateFileName("dcam");
  }
  
  public String getDateFileName(String fending)
  {
    String dn = getDateFolderName();
    String fn = dn + "_" + hours + "-" + minutes + "-" + seconds + "-" + (ms4 * 4) + "." + fending;
    return directory + "/" + dn + "/" + fn;
  }

  private void startBackgroundThread()
  {
    mBackgroundThread = new HandlerThread("ToFCameraBackground");
    mBackgroundThread.start();
    mBackgroundHandler = new Handler(mBackgroundThread.getLooper());
  }

  private void stopBackgroundThread()
  {
    mBackgroundThread.quitSafely();
    try
    {
      mBackgroundThread.join();
      mBackgroundThread = null;
      mBackgroundHandler = null;
    }
    catch(InterruptedException e)
    {
      e.printStackTrace();
    }
  }

  private final CameraDevice.StateCallback mStateCallback = new CameraDevice.StateCallback()
  {

    @Override
    public void onOpened(CameraDevice cameraDevice)
    {
      System.out.println("ToF camera onOpened called");
      try
      {
        camdev = cameraDevice;
        previewBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
        //previewBuilder.set(CaptureRequest.DISTORTION_CORRECTION_MODE, CameraMetadata.DISTORTION_CORRECTION_MODE_HIGH_QUALITY);
        previewBuilder.set(CaptureRequest.JPEG_ORIENTATION, 0);
        Range<Integer> fpsRange = new Range<Integer>(FPS_MIN, FPS_MAX);
        previewBuilder.set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, fpsRange);
        previewBuilder.addTarget(previewReader.getSurface());
        List<Surface> targetSurfaces = Arrays.asList(previewReader.getSurface());
        cameraDevice.createCaptureSession(targetSurfaces, 
          new CameraCaptureSession.StateCallback()
        {
          @Override
            public void onConfigured(CameraCaptureSession session)
          {
            System.out.println("ToF capture session configured.");
            camsession = session;
            previewBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
          }

          @Override
            public void onConfigureFailed(CameraCaptureSession session)
          {
            System.out.println("Creating ToF capture session failed!");
          }
        }
        , null);
      }
      catch(CameraAccessException e)
      {
        System.out.println("Camera access exception: " + e);
      }
    }

    @Override
      public void onDisconnected(CameraDevice cameraDevice)
    {
      System.out.println("ToF camera disconnected!");
      camsession.close();
      gotcamera = false;
    }

    @Override
      public void onError(CameraDevice cameraDevice, int error)
    {
      System.out.println("ToF camera open error #"+error+"!");
      gotcamera = false;
    }
  };

  CameraCaptureSession.CaptureCallback ToFCaptureCallback = new CameraCaptureSession.CaptureCallback()
  {
    @Override public void onCaptureCompleted(CameraCaptureSession session, CaptureRequest request, TotalCaptureResult result)
    {
      super.onCaptureCompleted(session, request, result);
      System.out.println("ToF onCaptureCompleted called.");
    }
  }; 

  private class ToFImageMaker implements Runnable
  {

    private final Image ToFImage;

    public ToFImageMaker(Image image)
    {
      ToFImage = image;
    }

    @Override
    public void run()
    {
      System.out.println("ToF image maker called.");
      short sample;
      int c, range, dCon;
      int[] percs = {0, 14, 29, 43, 57, 71, 86, 100};
      if (ToFImage != null && ToFImage.getFormat() == ImageFormat.DEPTH16)
      {
        System.out.println("*** Got ToF frame " + frnum + " ***");
        ShortBuffer shbuffer = ToFImage.getPlanes()[0].getBuffer().asShortBuffer();
        bpf = shbuffer.capacity();
        if (frnum == 0)
        {
          depth = new int[bpf];
          conf = new int[bpf];
          tdata = new int[bpf];
          tcon = new int[bpf];
        }
        for (c = 0; c < bpf; c++)
        {
          sample = shbuffer.get(c);
          range = (short) (sample & 0x1FFF);
          tdata[c] += range;
          dCon = (short) ((sample >> 13) & 0x7);
          // Convert to 0 (0%) to 7 (100%)
          if (dCon == 0) dCon = 7;
          else dCon -= 1;
          tcon[c] += percs[dCon];
        }
      }
      ToFImage.close();
      frnum++;
      if (frnum == numtoaverage)
      {
        dmin = 999999;
        dmax = -999999;
        for (c = 0; c < bpf; c++)
        {
          depth[c] = tdata[c] >> divshift;
          if (depth[c] < dmin && depth[c] > 10) dmin = depth[c];
          if (depth[c] > dmax) dmax = depth[c];
          conf[c] = tcon[c] >> divshift;
        }
        gotframe = true;
      } else
      {
        try
        {
          camsession.capture(previewBuilder.build(), ToFCaptureCallback, mBackgroundHandler);
        }
        catch(CameraAccessException e)
        {
          System.out.println("Camera access exception!" + e);
        }
      }
    }
  }
  
  public boolean isCamera2(int cam)
  {
    int camlevel = getCameraLevel(cam);
    // Only use fully functional camera2 devices for RGB
    if(camlevel == CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL ||
       camlevel == CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3)
       return true;
    // Depth camera and some chromebooks only have limited camera2 functionality
    if(isDepthCamera(cam) || allowlimited)
      if(camlevel == CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED)
        return true;
    return false;
  }
  
  public int getCameraLevel(int cam)
  {
    int camlevel = -1;
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      camlevel = chars.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL);
    }
    catch(CameraAccessException e)
    {
      System.out.println("Error in camera2 check: " + e);
      camlevel = -1;
    }
    return camlevel;
  }
  
  public boolean gotDepthCamera()
  {
    int cam = findDepthCamera();
    if(cam != -1) return true;
    return false;
  }

  public boolean isDepthCamera(int cam)
  {
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      final int[] capabilities = chars.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES);
      for (int capability : capabilities)
      {
        if (capability == CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)
          return true;
      }
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
    return false;
  }

  public int findDepthCamera()
  {
    int c, cam = -1;
    if (cameras.length > 0)
    {
      for (c = 0; c < cameras.length; c++)
      {
        if(isDepthCamera(c) && isCamera2(c))
        {
          cam = c;
          break;
        }
      }
    }
    return cam;
  }

  public int[] getLargestDepthSize(int dc)
  {
    int c, a, amax = 0;
    int[] ret = {0,0};
    if(dc == -1) return ret;
    int[][] ds = getSizes(dc);
    for(c=0; c<ds.length; c++)
    {
      a = ds[c][0] * ds[c][1];
      if(a > amax)
      {
        amax = a;
        ret[0] = ds[c][0];
        ret[1] = ds[c][1];
      }
    }
    return ret;
  }

  public int[][] getSizes(int cam)
  {
    int c;
    Size[] osizes;
    int[][] sizes = {{0},{0}};
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      StreamConfigurationMap streamConfigurationMap = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
      if(isDepthCamera(cam))
        osizes = streamConfigurationMap.getOutputSizes(ImageFormat.DEPTH16);
      else
        osizes = streamConfigurationMap.getOutputSizes(ImageFormat.JPEG);
      sizes = new int[osizes.length][2];
      for (c = 0; c < osizes.length; c++)
      {
        sizes[c][0] = osizes[c].getWidth();
        sizes[c][1] = osizes[c].getHeight();
      }
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
    return sizes;
  }

  public int[][] getFPSRanges(int cam)
  {
    int c;
    int[][] ranges = {{0},{0}};
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      Range<Integer>[] fpsRanges = chars.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES);
      if (fpsRanges != null)
      {
        ranges = new int[fpsRanges.length][2];
        for (c = 0; c < fpsRanges.length; c++)
        {
          ranges[c][0] = fpsRanges[c].getLower();
          ranges[c][1] = fpsRanges[c].getUpper();
        }
      }
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
    return ranges;
  }

  public int getLensFacing(int cam)
  {
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      if(chars.get(CameraCharacteristics.LENS_FACING) == CameraMetadata.LENS_FACING_FRONT)
        return 0;
      if(chars.get(CameraCharacteristics.LENS_FACING) == CameraMetadata.LENS_FACING_BACK)
        return 1;
      if(chars.get(CameraCharacteristics.LENS_FACING) == CameraMetadata.LENS_FACING_EXTERNAL)
        return 2;
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
    return -1;
  }

  public String getLensFacingName()
  {
    if(facing == 0) return "front";
    if(facing == 1) return "back";
    if(facing == 2) return "external";
    return "unknown";
  }

  public String getCameraLevelName()
  {
    switch(camlevel)
    {
      case CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY:
           return "legacy";
      //case CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL:
           //return "external";
      case CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED:
           return "limited";
      case CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL:
           return "full";
      case CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3:
           return "level3";
    }
    return "unknown";
  }

  private void getCameraInfo(int cam)
  {
    int c;
    float[] data;
    facing = getLensFacing(cam);
    camlevel = getCameraLevel(cam);
    try
    {
      CameraCharacteristics chars = cameraManager.getCameraCharacteristics(cameras[cam]);
      SizeF sensorSize = chars.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE);
      sensorwidth = sensorSize.getWidth();
      sensorheight = sensorSize.getHeight();
      focallength = chars.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)[0];
      // https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#LENS_INTRINSIC_CALIBRATION
      data = chars.get(CameraCharacteristics.LENS_INTRINSIC_CALIBRATION);
      if(data != null && data.length == 5)
      {
        for(c = 0; c < data.length; c++)
        {
          lensintrinsiccalibration[c] = data[c];
        }
      }
      // https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#LENS_POSE_ROTATION
      data = chars.get(CameraCharacteristics.LENS_POSE_ROTATION);
      if(data != null && data.length == 4)
      {
        for(c = 0; c < data.length; c++)
        {
          lensposerotation[c] = data[c];
        }
      }
      // https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#LENS_POSE_TRANSLATION
      data = chars.get(CameraCharacteristics.LENS_POSE_TRANSLATION);
      if(data != null && data.length == 3)
      {
        for(c = 0; c < data.length; c++)
        {
          lensposetranslation[c] = data[c];
        }
      }
    }
    catch(CameraAccessException e)
    {
      System.out.println("Could not initialize Camera Cache: " + e);
    }
  }

  private String floatsToString(float[] f)
  {
    int c;
    String str="";
    for(c=0; c<f.length; c++)
    {
      str += f[c];
      if(c!=(f.length-1)) str+=", ";
    }
    return str;
  }
  
  public float[] poseToAxes(float[] q)
  {
    float[] xyz = {0,0,0};
    // Convert from the quaternion coefficients (x,y,z,w) to the axis of rotation (a_x, a_y, a_z)
    // See https://developer.android.com/reference/android/hardware/camera2/CameraCharacteristics#LENS_POSE_ROTATION
    float theta = 2 * acos(q[3]);
    xyz[0] = q[0] / sin(theta/2);
    xyz[1] = q[1] / sin(theta/2);
    xyz[2] = q[2] / sin(theta/2);
    return xyz;
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
    int numb = headerlen + (width * height * 3) + extra;
    df = new byte[numb];
    df[0] = (byte) 'D';
    df[1] = (byte) 'C';
    df[2] = (byte) 'A';
    df[3] = (byte) 'M';
    df[4] = (byte) ftver; // File type version
    df[5] = (byte) headerlen; // Max 255 bytes!
    df[6] = (byte) ((width >> 8) & 0xFF);
    df[7] = (byte) (width & 0xFF);
    df[8] = (byte) ((height >> 8) & 0xFF);
    df[9] = (byte) (height & 0xFF);
    df[10] = (byte) numtoaverage; // Number of averages for depth
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
    for(c=0; c<(width*height); c++)
    {
      df[ind + 0] = (byte) ((depth[c] >> 8) & 0xFF);
      df[ind + 1] = (byte) (depth[c] & 0xFF);
      ind+=2;
    }
    for(c=0; c<(width*height); c++)
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
    width = w;
    height = h;
    numtoaverage = nta;
    yaw = ((b2i(data[11])*256) + b2i(data[12]))/100;
    pitch = ((b2i(data[13])*256) + b2i(data[14]))/100;
    roll = ((b2i(data[15])*256) + b2i(data[16]))/100;
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
