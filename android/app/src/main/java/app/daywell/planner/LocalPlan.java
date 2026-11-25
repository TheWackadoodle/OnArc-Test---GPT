package app.daywell.planner;

import android.content.*;
import org.json.*;
import java.time.*;

final class LocalPlan {
    static android.content.SharedPreferences prefs(Context c) {return c.getSharedPreferences("daywell",0);}
    static JSONArray arcs(Context c) throws JSONException {
        String raw=prefs(c).getString("plan",null);
        return raw==null?new JSONArray():new JSONObject(raw).getJSONArray("arcs");
    }
    static String[] agenda(Context c){
        LocalTime t=LocalTime.now();int minute=t.getHour()*60+t.getMinute();
        String current="Open time", next="Open time";
        try{
            JSONArray all=arcs(c);
            if(all.length()>0)next=all.getJSONObject(0).getString("name");
            for(int i=0;i<all.length();i++){
                JSONObject a=all.getJSONObject(i);int s=a.getInt("start");
                if(s<=minute && minute<a.getInt("end"))current=a.getString("name");
                if(s>minute){next=a.getString("name");break;}
            }
        }catch(JSONException e){current="Plan unavailable";}
        return new String[]{current,next};
    }
    static void changed(Context c){
        Nudge.schedule(c);
        DeviceSurfaces.refresh(c);
    }
}
