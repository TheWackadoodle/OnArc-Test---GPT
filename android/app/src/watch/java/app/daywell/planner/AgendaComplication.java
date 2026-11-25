package app.daywell.planner;

import android.app.PendingIntent;
import android.content.Intent;
import android.support.wearable.complications.*;

public class AgendaComplication extends ComplicationProviderService {
    @Override public void onComplicationUpdate(int id,int type,ComplicationManager manager){
        String[] agenda=LocalPlan.agenda(this);
        ComplicationData.Builder data=new ComplicationData.Builder(type);
        if(type==ComplicationData.TYPE_LONG_TEXT)data.setLongText(ComplicationText.plainText(agenda[0]+" · Next: "+agenda[1]));
        else if(type==ComplicationData.TYPE_SHORT_TEXT)data.setShortText(ComplicationText.plainText(agenda[0]));
        else{manager.noUpdateRequired(id);return;}
        data.setContentDescription(ComplicationText.plainText("Current arc: "+agenda[0]));
        data.setTapAction(PendingIntent.getActivity(this,0,new Intent(this,MainActivity.class),PendingIntent.FLAG_IMMUTABLE));
        manager.updateComplicationData(id,data.build());
    }
}
