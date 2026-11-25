package app.daywell.planner;

import android.Manifest;
import android.app.*;
import android.bluetooth.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;

public class MainActivity extends FlutterActivity {
    private MethodChannel.Result pending;
    private String document;
    private static final int POST=41,BT=42,EXACT=43,OPEN=44,CREATE=45;
    private static final int LIMIT=1024*1024;
    private static final UUID SERVICE=UUID.fromString("6372fca2-47ad-4834-82bf-b199df42a77f");
    private final ScheduledExecutorService io=Executors.newScheduledThreadPool(2);
    private boolean watch(){return getPackageManager().hasSystemFeature(PackageManager.FEATURE_WATCH);}
    private void finishRequest(Object value){if(pending!=null)pending.success(value);pending=null;document=null;}
    private void fail(String message){if(pending!=null)pending.error("daywell",message,null);pending=null;document=null;}
    private void persist(String key,boolean value)throws IOException{
        if(!LocalPlan.prefs(this).edit().putBoolean(key,value).commit())throw new IOException("Settings could not be saved.");
    }
    @Override public void configureFlutterEngine(FlutterEngine engine){
        super.configureFlutterEngine(engine);
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(),"app.daywell/local").setMethodCallHandler((call,result)->{
            if(pending!=null){result.error("busy","Finish the open request first.",null);return;}
            pending=result;
            try{
                var prefs=LocalPlan.prefs(this);
                switch(call.method){
                case "state":
                    Map<String,Object> state=new HashMap<>();state.put("watch",watch());state.put("plan",prefs.getString("plan",null));
                    for(String k:new String[]{"intro","military","nudges","alarm"})state.put(k,prefs.getBoolean(k,k.equals("intro")||k.equals("military")));
                    finishRequest(state);break;
                case "save":
                    String plan=(String)call.arguments;
                    if(plan.getBytes(StandardCharsets.UTF_8).length>LIMIT)throw new IOException("Plan exceeds 1 MiB.");
                    if(!prefs.edit().putString("plan",plan).commit())throw new IOException("Could not save this plan.");
                    LocalPlan.changed(this);finishRequest(null);break;
                case "nextNudge":long next=Nudge.next(this,new Intent());finishRequest(next==0?null:next);break;
                case "setting":
                    String key=call.argument("key");boolean enabled=Boolean.TRUE.equals(call.argument("value"));
                    if("nudges".equals(key)&&enabled){enableNudges();break;}
                    persist(key,enabled);Nudge.schedule(this);finishRequest(null);break;
                case "export":case "import":
                    boolean out=call.method.equals("export");document=out?(String)call.arguments:null;
                    Intent intent=new Intent(out?Intent.ACTION_CREATE_DOCUMENT:Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE)
                        .setType(out?"application/json":"*/*").putExtra(Intent.EXTRA_LOCAL_ONLY,true);
                    if(out)intent.putExtra(Intent.EXTRA_TITLE,"Daywell.json");
                    startActivityForResult(intent,out?CREATE:OPEN);break;
                case "sync":
                    document=(String)call.arguments;
                    if(Build.VERSION.SDK_INT>=31 && checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT)!=PackageManager.PERMISSION_GRANTED)
                        requestPermissions(new String[]{Manifest.permission.BLUETOOTH_CONNECT},BT);
                    else choosePeer();
                    break;
                default:result.notImplemented();pending=null;
                }
            }catch(Exception e){fail(e.toString());}
        });
    }
    private void enableNudges()throws IOException{
        if(Build.VERSION.SDK_INT>=33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED){
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},POST);return;
        }
        if(Build.VERSION.SDK_INT>=31&&!getSystemService(AlarmManager.class).canScheduleExactAlarms()){
            startActivityForResult(new Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,Uri.parse("package:"+getPackageName())),EXACT);return;
        }
        persist("nudges",true);Nudge.schedule(this);finishRequest(null);
    }
    @Override public void onRequestPermissionsResult(int code,String[] names,int[] grants){
        super.onRequestPermissionsResult(code,names,grants);
        if((code!=POST&&code!=BT)||pending==null)return;
        try{if(grants.length==0||grants[0]!=PackageManager.PERMISSION_GRANTED)fail("Permission was declined.");
            else if(code==POST)enableNudges();else choosePeer();
        }catch(Exception e){fail(e.toString());}
    }
    @Override protected void onActivityResult(int code,int status,Intent data){
        super.onActivityResult(code,status,data);
        if(pending==null)return;
        try{
            if(code==EXACT){if(Build.VERSION.SDK_INT>=31&&!getSystemService(AlarmManager.class).canScheduleExactAlarms())fail("Exact timing access is off.");else enableNudges();return;}
            if(code!=OPEN&&code!=CREATE)return;
            if(status!=RESULT_OK||data==null){finishRequest(null);return;}
            Uri uri=data.getData();
            if(code==CREATE){try(OutputStream out=getContentResolver().openOutputStream(uri,"wt")){out.write(document.getBytes(StandardCharsets.UTF_8));}finishRequest(null);}
            else {try(InputStream in=getContentResolver().openInputStream(uri)){ByteArrayOutputStream bytes=new ByteArrayOutputStream();byte[] chunk=new byte[8192];int n;
                while((n=in.read(chunk))!=-1){if(bytes.size()+n>LIMIT)throw new IOException("Backup exceeds 1 MiB.");bytes.write(chunk,0,n);}finishRequest(bytes.toString("UTF-8"));}}
        }catch(Exception e){fail(e.toString());}
    }
    private void choosePeer(){
        BluetoothAdapter adapter=getSystemService(BluetoothManager.class).getAdapter();
        if(adapter==null||!adapter.isEnabled()){fail("Turn Bluetooth on first.");return;}
        List<BluetoothDevice> peers=new ArrayList<>(adapter.getBondedDevices());
        if(peers.isEmpty()){fail("Pair the phone and watch in system settings first.");return;}
        String[] names=new String[peers.size()];for(int i=0;i<names.length;i++)names[i]=peers.get(i).getName()+" · "+peers.get(i).getAddress();
        new AlertDialog.Builder(this).setTitle(watch()?"Receive from paired phone":"Send to paired watch")
            .setItems(names,(dialog,i)->exchange(adapter,peers.get(i))).setOnCancelListener(d->finishRequest(null)).show();
    }
    private void exchange(BluetoothAdapter adapter,BluetoothDevice device){
        final String plan=document;final boolean receive=watch();
        io.execute(()->{
            try{
                String received=null;
                if(receive){
                    try(BluetoothServerSocket server=adapter.listenUsingRfcommWithServiceRecord("Daywell",SERVICE);
                        BluetoothSocket socket=server.accept(60000)){
                        if(!socket.getRemoteDevice().equals(device))throw new IOException("Unexpected paired device.");
                        var timeout=io.schedule(()->close(socket),30,TimeUnit.SECONDS);
                        try{DataInputStream in=new DataInputStream(socket.getInputStream());int n=in.readInt();
                            if(n<1||n>LIMIT)throw new IOException("Invalid plan length.");byte[] bytes=new byte[n];in.readFully(bytes);received=new String(bytes,StandardCharsets.UTF_8);
                        }finally{timeout.cancel(false);}
                    }
                }else{
                    try(BluetoothSocket socket=device.createRfcommSocketToServiceRecord(SERVICE)){
                        var timeout=io.schedule(()->close(socket),45,TimeUnit.SECONDS);
                        try{socket.connect();byte[] bytes=plan.getBytes(StandardCharsets.UTF_8);DataOutputStream out=new DataOutputStream(socket.getOutputStream());
                            out.writeInt(bytes.length);out.write(bytes);out.flush();
                        }finally{timeout.cancel(false);}
                    }
                }
                final String payload=received;runOnUiThread(()->finishRequest(payload));
            }catch(Exception e){runOnUiThread(()->fail("Transfer failed. Open Receive on the watch first. "+e.getMessage()));}
        });
    }
    private static void close(BluetoothSocket socket){try{socket.close();}catch(IOException ignored){}}
    @Override protected void onDestroy(){io.shutdown();super.onDestroy();}
}
