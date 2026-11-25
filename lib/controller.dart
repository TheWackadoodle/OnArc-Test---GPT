import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'day.dart';

class Planner extends ChangeNotifier {
  static const bridge=MethodChannel('app.daywell/local');
  Day day=Day.empty();
  bool watch=false,ready=false,intro=true,military=true,nudges=false,alarm=false,busy=false;
  Future<void> load() async {
    final state=(await bridge.invokeMapMethod<String,dynamic>('state'))!;
    watch=state['watch'];intro=state['intro'];military=state['military'];
    nudges=state['nudges'];alarm=state['alarm'];
    final raw=state['plan'] as String?;
    day=raw!=null?Day.decode(raw):watch?Day.empty():Day.sample();
    if(raw==null) await bridge.invokeMethod('save',day.encode());
    ready=true;notifyListeners();
  }
  Future<void> save(Day candidate) async {
    if(busy) throw StateError('Another change is being saved.');
    busy=true;
    try{await bridge.invokeMethod('save',candidate.encode());day=candidate;notifyListeners();}
    finally{busy=false;}
  }
  Future<void> setting(String key,bool value) async {
    await bridge.invokeMethod('setting',{'key':key,'value':value});await load();
  }
  Future<void> export() => bridge.invokeMethod('export',day.encode());
  Future<void> import() async {final raw=await bridge.invokeMethod<String>('import');if(raw!=null)await save(Day.decode(raw));}
  Future<void> sync() async {
    final raw=await bridge.invokeMethod<String>('sync',day.encode());
    if(watch && raw!=null)await save(Day.decode(raw));
  }
  Future<int?> nextNudge()=>bridge.invokeMethod<int>('nextNudge');
}
