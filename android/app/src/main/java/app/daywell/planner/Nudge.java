package app.daywell.planner;

import android.app.*;
import android.content.*;
import android.media.*;
import android.os.Build;
import android.provider.Settings;
import org.json.*;
import java.time.*;

public class Nudge extends BroadcastReceiver {
    static final String FIRE="app.daywell.START";
    static long next(Context c,Intent event){
        if(!LocalPlan.prefs(c).getBoolean("nudges",false))return 0;
        long best=Long.MAX_VALUE;Instant now=Instant.now();ZoneId zone=ZoneId.systemDefault();
        try{JSONArray arcs=LocalPlan.arcs(c);
            for(int i=0;i<arcs.length();i++){JSONObject a=arcs.getJSONObject(i);
                long at=Schedule.next(a.getInt("start"),now,zone).toEpochMilli();
                if(at<best){best=at;event.putExtra("at",at).putExtra("text",a.getString("name")+", "+(a.getInt("end")-a.getInt("start"))+" min, starting now");}
            }
        }catch(JSONException e){return 0;}
        return best==Long.MAX_VALUE?0:best;
    }
    static void schedule(Context c){
        Intent event=new Intent(c,Nudge.class).setAction(FIRE);
        long at=next(c,event);
        PendingIntent pi=PendingIntent.getBroadcast(c,0,event,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        AlarmManager am=c.getSystemService(AlarmManager.class);am.cancel(pi);
        if(at==0 || (Build.VERSION.SDK_INT>=31&&!am.canScheduleExactAlarms()))return;
        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,at,pi);
    }
    @Override public void onReceive(Context c,Intent i){
        if(FIRE.equals(i.getAction()) && LocalPlan.prefs(c).getBoolean("nudges",false)){
            boolean loud=LocalPlan.prefs(c).getBoolean("alarm",false);
            String channel=loud?"alarm":"starts";
            NotificationManager nm=c.getSystemService(NotificationManager.class);
            NotificationChannel ch=new NotificationChannel(channel,loud?"Arc alarm sounds":"Arc starts",NotificationManager.IMPORTANCE_HIGH);
            ch.enableVibration(true);
            ch.setSound(loud?Settings.System.DEFAULT_ALARM_ALERT_URI:null,new AudioAttributes.Builder().setUsage(loud?AudioAttributes.USAGE_ALARM:AudioAttributes.USAGE_NOTIFICATION).build());
            nm.createNotificationChannel(ch);
            PendingIntent open=PendingIntent.getActivity(c,0,new Intent(c,MainActivity.class),PendingIntent.FLAG_IMMUTABLE);
            nm.notify(1,new Notification.Builder(c,channel).setSmallIcon(R.drawable.dial).setContentTitle("Daywell").setContentText(i.getStringExtra("text")).setLocalOnly(true).setContentIntent(open).setAutoCancel(true).build());
        }
        LocalPlan.changed(c);
    }
}
