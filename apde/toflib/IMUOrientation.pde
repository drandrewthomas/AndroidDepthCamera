import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Environment;
import android.app.Activity;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

public class IMUOrientation
{

  private float gravity[];
  private float magnetic[];
  private float accels[] = new float[3];
  private float mags[] = new float[3];
  private float[] values = new float[3];
  public float yaw;
  public float pitch;
  public float roll;
  Context appctx;

  public IMUOrientation(Context ctx)
  {
    appctx = ctx;
    SensorManager sManager = (SensorManager) appctx.getSystemService(Context.SENSOR_SERVICE);
    sManager.registerListener(mySensorEventListener, sManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_NORMAL);
    sManager.registerListener(mySensorEventListener, sManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_NORMAL);
  }

  private SensorEventListener mySensorEventListener = new SensorEventListener()
  {
    public void onAccuracyChanged(Sensor sensor, int accuracy)
    {
    }

    public void onSensorChanged(SensorEvent event)
    {
      switch(event.sensor.getType())
      {
        case Sensor.TYPE_MAGNETIC_FIELD:
          mags = event.values.clone();
          break;
        case Sensor.TYPE_ACCELEROMETER:
          accels = event.values.clone();
          break;
      }
      if(mags != null && accels != null)
      {
        gravity = new float[9];
        magnetic = new float[9];
        SensorManager.getRotationMatrix(gravity, magnetic, accels, mags);
        float[] outGravity = new float[9];
        SensorManager.remapCoordinateSystem(gravity, SensorManager.AXIS_X, SensorManager.AXIS_Z, outGravity);
        SensorManager.getOrientation(outGravity, values);
        yaw = values[0] * 57.2957795f;
        pitch = values[1] * 57.2957795f;
        roll = values[2] * 57.2957795f;
        mags = null;
        accels = null;
      }
    }
  };

}
