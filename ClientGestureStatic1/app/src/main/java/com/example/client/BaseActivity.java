package com.example.client;

import android.annotation.SuppressLint;
import android.app.Activity;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.lang.Exception;import java.lang.Float;import java.lang.Override;import java.lang.String;import java.lang.System;import java.lang.Void;import java.net.Socket;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;import com.example.client.MainActivity;import com.example.client.R;import com.example.client.SelectGesture;

@SuppressLint("NewApi")
public class BaseActivity extends Activity implements SensorEventListener {

	TextView textResponse, gestureText;
	Button buttonConnect, buttonPress, buttonClear, buttonSubmit,
			buttonGesture;
	List<Float> xPoints;
	List<Float> yPoints;
	List<Float> zPoints;
	Sensor sensor = null;
	SensorManager sensorManager = null;
	SensorEventListener sListener;
	TestGesture testGesture;
	static int checkUpdate = 0;
	static String resultGesture = null;
	MyClientTask connectServer = null;
	MainActivity mainActivity = null;
	SelectGesture selectGesture = null;
	PlayFragment playFragment = null;
	float x1, y1, z1;
	int check = 0;
	float[] gravity = new float[3];

	@SuppressLint("NewApi")
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		mainActivity = new MainActivity();
		playFragment = new PlayFragment();
		selectGesture = new SelectGesture();
		if (savedInstanceState == null) {

		}
		testGesture = new TestGesture();
		sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
		sensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
		sListener = this;
		sensorManager.unregisterListener(sListener, sensor);
		xPoints = new ArrayList<Float>();
		yPoints = new ArrayList<Float>();
		zPoints = new ArrayList<Float>();
	}

	@SuppressLint("NewApi")
	public void playGameSubmit(View v) {
		// TODO Auto-generated method stub
		getFragmentManager().beginTransaction()
				.replace(R.id.linearFrag, playFragment).commit();
	}

	public void goToGestures(View v) {
		// TODO Auto-generated method stub
		getFragmentManager().beginTransaction()
				.replace(R.id.linearFrag, selectGesture).commit();
	}

	public void clearClick(View v) {
		// TODO Auto-generated method stub
		if (connectServer != null) {
			connectServer = null;
			textResponse.setText("Connection closed");
		}
	}

	public void connectToServer(View arg0) {

		if (mainActivity.editTextAddress != null) {
			Log.d("Server IP", mainActivity.editTextAddress.getText()
					.toString());
			connectServer = new MyClientTask(mainActivity.editTextAddress
					.getText().toString(), 8080);
			Log.d("Server IP", mainActivity.editTextAddress.getText()
					.toString());
			connectServer.execute();
		} else {
			Log.d("Server IP", "NULL");
		}
	}

	public class MyClientTask extends AsyncTask<Void, Void, Void> {

		String dstAddress;
		int dstPort;
		String response = "";
		MainActivity mainActivity = new MainActivity();

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
					if (BaseActivity.checkUpdate == 1) {
						Log.d("Gesture Sent", BaseActivity.resultGesture);
						System.out.println("Gesture Sent : "
								+ BaseActivity.resultGesture);
						printStream.print(BaseActivity.resultGesture);
						printStream.flush();
						BaseActivity.checkUpdate = 0;
						BaseActivity.resultGesture = null;
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
			// textResponse.setText(response);
			super.onPostExecute(result);
		}

	}

	@Override
	public void onSensorChanged(SensorEvent event) {
		// TODO Auto-generated method stub
		if (event.sensor == sensor) {
			final float alpha = (float) 0.8;

			gravity[0] = alpha * gravity[0] + (1 - alpha) * event.values[0];
			gravity[1] = alpha * gravity[1] + (1 - alpha) * event.values[1];
			gravity[2] = alpha * gravity[2] + (1 - alpha) * event.values[2];

			// Log.d("Event sensor Name", event.sensor.toString());
			// Log.d("Accelerometer sensor Name", sensor.toString());

			/*
			 * check++; Log.d("Check Value", check + ""); if (check >= 5 &&
			 * dataPoints.size() <= 20) { if ((xPoint - x1 >= 0.1 || yPoint - y1
			 * >= 0.1 || zPoint - z1 >= 0.1) || (xPoint - x1 <= -0.1 || yPoint -
			 * y1 <= -0.1 || zPoint - z1 <= -0.1)) { dataPoints.add("[ " +
			 * xPoint + " " + yPoint + " " + zPoint + " ] ;"); } }
			 */
			xPoints.add(event.values[0] - gravity[0]);
			yPoints.add(event.values[1] - gravity[1]);
			zPoints.add(event.values[2] - gravity[2]);
		}
	}

	@Override
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
		// TODO Auto-generated method stub

	}

	public void checkGesture() throws Exception {
		gestureText = (TextView) findViewById(R.id.gestureText);
		ArrayList<String> dataPoints = new ArrayList<String>();
		int i = 5;
		if (xPoints.size() >= 5 && yPoints.size() >= 5
				&& zPoints.size() >= 5) {
			float xAvg, yAvg, zAvg;
			xAvg = getAvg(xPoints);
			yAvg = getAvg(yPoints);
			zAvg = getAvg(zPoints);
			if (getAbs(xAvg) > getAbs(yAvg) && getAbs(xAvg) > getAbs(zAvg)) {
				if (xAvg < 0) {
					resultGesture = "right";
				} else {
					resultGesture = "left";
				}

			} else if (getAbs(yAvg) > getAbs(xAvg)
					&& getAbs(yAvg) > getAbs(zAvg)) {
				if (zAvg < 0) {
					resultGesture = "up";
				} else {
					resultGesture = "down";
				}

			} else if (getAbs(zAvg) > getAbs(xAvg)
					&& getAbs(zAvg) > getAbs(yAvg)) {
				if (zAvg < 0) {
					resultGesture = "up";
				} else {
					resultGesture = "down";
				}

			} else {
				resultGesture = "others";
			}

			checkUpdate = 1;
			Log.d("Result Gesture", resultGesture);
			gestureText.setText(resultGesture);
			xPoints = new ArrayList<Float>();
			yPoints = new ArrayList<Float>();
			zPoints = new ArrayList<Float>();
		} else {
			xPoints = new ArrayList<Float>();
			yPoints = new ArrayList<Float>();
			zPoints = new ArrayList<Float>();
			gestureText.setText("Gesture not recognized(Hold for more time to collect more data)");
		}
	}

	public float getAvg(List<Float> temp) {
		int i = 0;
		float avg = 0;

		for (i = 0; i < temp.size(); i++) {
			avg += temp.get(i);
		}
		avg = avg / (temp.size() - 1);
		float sum = 0;
		for (i = 0; i < temp.size(); i++) {
			sum += temp.get(i) - avg;
		}
		// return sum;
		Log.d("Average : " , avg+"");
		return (temp.get(temp.size() - 1) - temp.get(0));
	}

	public float getAbs(float temp) {
		if (temp < 0) {
			return temp * (-1);
		} else {
			return temp;
		}
	}
}
