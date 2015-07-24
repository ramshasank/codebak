package com.example.client;

import android.app.Activity;
import android.app.Fragment;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.Button;import com.example.client.BaseActivity;import com.example.client.R;import java.lang.Exception;import java.lang.Override;import java.lang.String;

public class PlayFragment extends Fragment {

	private View v = null;
	private Button buttonHold=null;
	private String filename = null;
	BaseActivity baseActivity=null;
	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
		baseActivity = (BaseActivity) activity;
		Log.d("In Attach", "Balu");
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		Log.d("In on create bundle", " Picture Preview Created ");
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
    	super.onCreateView(inflater, container, savedInstanceState);
		v = inflater.inflate(R.layout.play_game, container, false);
		buttonHold = (Button)v.findViewById(R.id.holdButton);
		buttonHold.setOnTouchListener(buttonPressListener);
		buttonHold.setOnClickListener(buttonPressClickListener);
		  		return v;

	}
	public OnTouchListener buttonPressListener = new OnTouchListener() {

		@Override
		public boolean onTouch(View v, MotionEvent event) {
			// TODO Auto-generated method stub
			baseActivity.sensorManager.registerListener(baseActivity.sListener, baseActivity.sensor,
					SensorManager.SENSOR_DELAY_NORMAL);
			return false;
		}
	};
	public OnClickListener buttonPressClickListener = new OnClickListener() {

		@Override
		public void onClick(View arg0) {
			baseActivity.sensorManager.unregisterListener(baseActivity.sListener, baseActivity.sensor);
			try {
				baseActivity.checkGesture();
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	};




}
