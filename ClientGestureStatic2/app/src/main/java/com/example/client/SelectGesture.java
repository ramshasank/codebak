package com.example.client;

import android.app.Activity;
import android.app.Fragment;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

public class SelectGesture extends Fragment{

	private View v = null;
	private String filename = null;
	@Override
	public void onAttach(Activity activity) {
		super.onAttach(activity);
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
		v = inflater.inflate(R.layout.select_gesture, container, false);
 		return v;

	}

}
