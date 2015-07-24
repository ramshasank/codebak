package com.example.socketclient;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.speech.RecognizerIntent;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import android.hardware.Sensor;
import android.hardware.SensorManager;

import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import static android.widget.Toast.LENGTH_SHORT;

public class MainActivity extends Activity implements SensorEventListener {
  private String TAG = "MainActivity";

  TextView textResponse;
  EditText editTextAddress, editTextPort, editTextCommand;
  Button buttonConnect,buttonClear,buttonSendCommand,buttonStop, buttonSpeak, buttonFaster, buttonSlower,
    buttonStopSign, buttonGoSign, buttonLeftSign, buttonRightSign, buttonSlowSign, buttonDNESign, buttonTweet, buttonOff, buttonOn;
  String command;
  Boolean checkupdate=false;
  protected static final int RESULT_SPEECH = 1;

  Runnable r;
  Handler handler;
  Random random;
  private Button dance;
  private int ran;
  private TextView acceleration;
  private SensorManager sm;
  private Sensor accelerometer;
  private long lastUpdate = 0;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
  
    editTextAddress = (EditText)findViewById(R.id.address);
    editTextPort = (EditText)findViewById(R.id.port);
    editTextCommand = (EditText)findViewById(R.id.command);
    buttonConnect = (Button)findViewById(R.id.connect);
    buttonClear = (Button)findViewById(R.id.clear);
    buttonSendCommand = (Button)findViewById(R.id.sendCommand);
    buttonSpeak = (Button)findViewById(R.id.speakBtn);
    buttonSlower = (Button)findViewById(R.id.buttonSlower);
    buttonFaster = (Button)findViewById(R.id.buttonFaster);
    buttonStopSign= (Button)findViewById(R.id.buttonStopSign);
    buttonGoSign = (Button)findViewById(R.id.buttonGoSign);
    buttonLeftSign = (Button)findViewById(R.id.buttonLeftSign);
    buttonRightSign = (Button)findViewById(R.id.buttonRightSign);
    buttonSlowSign = (Button)findViewById(R.id.buttonSlowSign);
    buttonDNESign = (Button)findViewById(R.id.buttonDNE);
    buttonTweet = (Button)findViewById(R.id.buttonTweet);
    buttonOff = (Button)findViewById(R.id.buttonOff);
    buttonOn = (Button)findViewById(R.id.buttonOn);
    textResponse = (TextView)findViewById(R.id.response);

    acceleration = (TextView)findViewById(R.id.acceleration);

    random = new Random();
      /*
    r = new Runnable() {
      @Override
      public void run() {

          ran = random.nextInt(5);

          if (ran == 0) {
              command = "smile";
              checkupdate = true;

          } else if (ran == 1) {
              command = "left";
              checkupdate = true;


          } else if (ran == 2) {
              command = "right";
              checkupdate = true;
          } else if (ran == 3) {
              command = "backward";
              checkupdate = true;
          } else if (ran == 4) {
              command = "forward";
              checkupdate = true;
          } else {
              command = "stop";
              checkupdate = true;

          }
          Toast.makeText(MainActivity.this, "" + ran, LENGTH_SHORT).show();
          if (handler == null)
              handler = new Handler();//.postDelayed(r, 3000);
          handler.postDelayed(r, 3000);
      }};
      */

    buttonSpeak.setOnClickListener(new View.OnClickListener() {
     @Override
     public void onClick(View v) {

         Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
         intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                 RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);

         try {
             startActivityForResult(intent, RESULT_SPEECH);
             editTextCommand.setText("");
         } catch (ActivityNotFoundException a) {
             Toast t = Toast.makeText(getApplicationContext(),
                     "Your device doesn't support Speech to Text",
                     Toast.LENGTH_SHORT);
             t.show();
         }
     }
    });

    buttonStop=(Button) findViewById(R.id.stop);
    buttonStop.setOnClickListener(new OnClickListener() {
        @Override
        public void onClick(View arg0) {
            // TODO Auto-generated method stub
            command="stop";
            checkupdate=true;
        }
    });

    buttonSlower.setOnClickListener(new OnClickListener(){

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command="slower";
         checkupdate=true;
     }

    });

    buttonFaster.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "faster";
         checkupdate = true;
     }

    });

    buttonStopSign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "stopsign";
         checkupdate = true;
     }

    });

    buttonGoSign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "gosign";
         checkupdate = true;
     }

    });

    buttonLeftSign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "leftsign";
         checkupdate = true;
     }

    });

    buttonRightSign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "rightsign";
         checkupdate = true;
     }

    });

    buttonSlowSign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "slowsign";
         checkupdate = true;
     }

    });

    buttonDNESign.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "dnesign";
         checkupdate = true;
     }

    });
    buttonTweet.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "tweet";
         checkupdate = true;
     }

    });
    buttonOff.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "off";
         checkupdate = true;
     }

    });
    buttonOn.setOnClickListener(new OnClickListener() {

     @Override
     public void onClick(View arg0) {
         // TODO Auto-generated method stub
         command = "on";
         checkupdate = true;
     }

    });

    buttonConnect.setOnClickListener(buttonConnectOnClickListener);

    buttonClear.setOnClickListener(new OnClickListener(){

    @Override
    public void onClick(View v) {
        textResponse.setText("");
        editTextCommand.setText("");
    }});

    buttonSendCommand.setOnClickListener(buttonSendCommandOnClickListener);
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data)
  {
    super.onActivityResult(requestCode, resultCode, data);

    if (requestCode == RESULT_SPEECH && resultCode == RESULT_OK) {
        ArrayList<String> results = data.getStringArrayListExtra(
                RecognizerIntent.EXTRA_RESULTS);
        editTextCommand.setText(results.get(0));

        Toast.makeText(getApplicationContext(),
                " " + results.get(0),
                LENGTH_SHORT).show();
        String text = results.get(0);
        if (text.equalsIgnoreCase("left"))
        {
            Log.v(TAG,"Left");
            command="left";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("right"))
        {
            Log.v(TAG,"Right");
            command="right";
            checkupdate=true;

        }
        else if(text.equalsIgnoreCase("forward"))
        {
            Log.v(TAG,"Forward");
            command="forward";
            checkupdate=true;

        }
        else if(text.equalsIgnoreCase("back"))
        {
            Log.v(TAG,"Back");
            command="back";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("stop"))
        {
            Log.v(TAG,"Stop");
            command="stop";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("laugh"))
        {
            Log.v(TAG,"Laugh");
            command="laugh";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("faster"))
        {
            Log.v(TAG,"Faster");
            command="faster";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("slower"))
        {
            Log.v(TAG,"Slower");
            command="slower";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("tweet"))
        {
            Log.v(TAG,"Tweet");
            command="tweet";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("on"))
        {
            Log.v(TAG,"On");
            command="on";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("off"))
        {
            Log.v(TAG,"Off");
            command="off";
            checkupdate=true;
        }
        else if(text.equalsIgnoreCase("smile"))
        {
            Log.v(TAG,"Smile");
            command="smile";
            checkupdate=true;
        }

        Log.v(TAG," " + results.get(0));
    }
  }

  OnClickListener buttonConnectOnClickListener =
    new OnClickListener(){

        @Override
        public void onClick(View arg0) {
        MyClientTask myClientTask = new MyClientTask(
            editTextAddress.getText().toString(),
            Integer.parseInt(editTextPort.getText().toString()));
        myClientTask.execute();
    }};

  OnClickListener buttonSendCommandOnClickListener =
    new OnClickListener(){

        @Override
        public void onClick(View arg0) {
        command = editTextCommand.getText().toString();
        checkupdate=true;
    }};

  @Override
  protected void onResume() {
    super.onResume();
    sm = (SensorManager)getSystemService(SENSOR_SERVICE);
    accelerometer=sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    sm.registerListener(this,accelerometer,SensorManager.SENSOR_DELAY_NORMAL);
  }

  @Override
  protected void onPause() {
    super.onPause();
    sm.unregisterListener(this);
    if(handler != null)
        handler.removeCallbacks(r);
  }

  @Override
  public void onSensorChanged(SensorEvent event) {
        float x= event.values[0];
        float y= event.values[1];
        float z= event.values[2];
        long curTime = System.currentTimeMillis();
        if ((curTime - lastUpdate) > 500) {
            lastUpdate = curTime;
            if (x > 5.0) {
                command="left";
                checkupdate=true;
                acceleration.setText("Left");
            } else if (x < -4.0) {
                command="right";
                checkupdate=true;
                acceleration.setText("Right");
            } else if (y > 4.0) {
                command="forward";
                checkupdate=true;
                acceleration.setText("Backward");
            } else if (y < -4.0) {
                command="back";
                checkupdate=true;
                acceleration.setText("Forward");
            } else {
                //command="stop";
                //checkupdate=true;
                acceleration.setText("Stop");
            }

        }
  }

  @Override
  public void onAccuracyChanged(Sensor sensor, int accuracy) {
    // TODO Auto-generated method stub
  }

  public class MyClientTask extends AsyncTask<Void, Void, Void> {
    String dstAddress;
    int dstPort;
    String response = "";

    MyClientTask(String addr, int port) {
        dstAddress = addr;
        dstPort = port;
    }

    @Override
    protected Void doInBackground(Void... arg0) {
        OutputStream outputStream;
        Socket socket = null;

        try {
            socket = new Socket(dstAddress, dstPort);
            Log.d("MyClient Task", "Destination Address : " + dstAddress);
            Log.d("MyClient Task", "Destination Port : " + dstPort + "");
            outputStream = socket.getOutputStream();
            PrintStream printStream = new PrintStream(outputStream);

            while (true) {
                if(checkupdate)
                {
                    Log.d("Command", command);
                    Log.d("checkUpdate", checkupdate.toString());
                    printStream.print(command);
                    printStream.flush();
                    Log.d("Socket connection", socket.isClosed() + "");
                    checkupdate=false;
                }
            }
        } catch (UnknownHostException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            response = "UnknownHostException: " + e.toString();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            response = "IOException: " + e.toString();
        } finally {
            if (socket != null) {
                try {
                    socket.close();
                } catch (IOException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                }
            }
        }

        return null;
    }

    @Override
    protected void onPostExecute(Void result) {
      textResponse.setText(response);
      super.onPostExecute(result);
    }
  }
}