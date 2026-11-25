package app.daywell.planner;

import android.content.ComponentName;
import android.content.Context;
import android.support.wearable.complications.ProviderUpdateRequester;
import androidx.wear.tiles.TileService;
import androidx.wear.tiles.TileBuilders;
import androidx.wear.tiles.RequestBuilders;
import androidx.wear.protolayout.ColorBuilders;
import androidx.wear.protolayout.DimensionBuilders;
import androidx.wear.protolayout.LayoutElementBuilders;
import androidx.wear.protolayout.ResourceBuilders;
import androidx.wear.protolayout.TimelineBuilders;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

public class AgendaTile extends TileService {
    public static void refresh(Context c){
        TileService.getUpdater(c).requestUpdate(AgendaTile.class);
        new ProviderUpdateRequester(c,new ComponentName(c,AgendaComplication.class)).requestUpdateAll();
    }
    private LayoutElementBuilders.Text line(String text,int sp){
        return new LayoutElementBuilders.Text.Builder().setText(text)
            .setFontStyle(new LayoutElementBuilders.FontStyle.Builder().setSize(DimensionBuilders.sp(sp))
                .setColor(ColorBuilders.argb(0xffd9e6de)).build()).build();
    }
    @Override protected ListenableFuture<TileBuilders.Tile> onTileRequest(RequestBuilders.TileRequest request){
        String[] labels=LocalPlan.agenda(this);
        var column=new LayoutElementBuilders.Column.Builder().addContent(line("Now",13))
            .addContent(line(labels[0],19)).addContent(line("Next",13)).addContent(line(labels[1],16)).build();
        var layout=new LayoutElementBuilders.Layout.Builder().setRoot(column).build();
        var entry=new TimelineBuilders.TimelineEntry.Builder().setLayout(layout).build();
        return Futures.immediateFuture(new TileBuilders.Tile.Builder().setResourcesVersion("1").setFreshnessIntervalMillis(60000)
                .setTileTimeline(new TimelineBuilders.Timeline.Builder().addTimelineEntry(entry).build()).build());
    }
    @Override protected ListenableFuture<ResourceBuilders.Resources> onTileResourcesRequest(RequestBuilders.ResourcesRequest request){
        return Futures.immediateFuture(new ResourceBuilders.Resources.Builder().setVersion("1").build());
    }
}
