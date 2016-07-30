package com.weforpay.plugin.esptouch;

import java.util.List;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.espressif.iot.esptouch.EsptouchTask;
import com.espressif.iot.esptouch.IEsptouchListener;
import com.espressif.iot.esptouch.IEsptouchResult;

import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Handler;


public class EspTouch extends CordovaPlugin {
	final String TAG = "EspTouch";
	
	boolean mInited = false;
	@Override
	public boolean execute(String action, JSONArray args,
			CallbackContext callbackContext) throws JSONException {
		if(!this.mInited){
			this.init(args, callbackContext);
		}
		if ( action.equalsIgnoreCase("init") ) {	
			this.init(args,callbackContext);
            return true;
        }else if ( action.equalsIgnoreCase("scan") ) {
            this.scan(args, callbackContext);
            return true;        
        }
		else if ( action.equalsIgnoreCase("cancel") ) {
            this.cancel(args, callbackContext);
            return true;        
        }
		return super.execute(action, args, callbackContext);
	}
	
	CallbackContext mSeeCallback = null;
	
	Context mContext = null;
	Handler mCordovaHander  = null;
	
	EsptouchAsyncTask mScanTask = null;
	void init(JSONArray args,
			CallbackContext callbackContext){
		mContext = this.cordova.getActivity();
		mCordovaHander = new Handler();
		
	}
	void scan(JSONArray args,
			CallbackContext callbackContext) throws JSONException{	
		String ssid = args.getString(0);
		String bssid =  args.getString(1);
		String pwd = args.getString(2);
		boolean hiden = args.getBoolean(3);
		
		mScanTask  =new  EsptouchAsyncTask(new EsptouchTask(ssid,bssid,pwd,hiden,this.mContext),callbackContext);
		mScanTask.execute();
	}	
	private class EsptouchAsyncTask extends AsyncTask<String, Void, List<IEsptouchResult>> implements IEsptouchListener{
		
		EsptouchTask mTask = null;
		CallbackContext mCallback = null;
		public EsptouchAsyncTask(EsptouchTask task,CallbackContext callback){
			this.mTask = task;
			this.mCallback = callback;
		}
		@Override
		protected List<IEsptouchResult> doInBackground(String... arg0) {
						
			this.mTask.setEsptouchListener(this);
			this.mTask.executeForResults(3);
			return null;
		}
		@Override
		public void onEsptouchResultAdded(IEsptouchResult result) {
			if(result.isSuc()){
				JSONObject jo = new JSONObject();
				try {
					jo.put("address", result.getInetAddress().getHostAddress());
					this.mCallback.success(jo);
				} catch (JSONException e) {
					this.mCallback.error("get ip failed");
					e.printStackTrace();
				}
				
			}else{
				this.mCallback.error("scan failed");
			}
		}
		
	}
	void cancel(JSONArray args,
			CallbackContext callbackContext) throws JSONException{	
		if(mScanTask != null){
			mScanTask.cancel(true);
			mScanTask = null;
		}
		callbackContext.success();
	}	
}
