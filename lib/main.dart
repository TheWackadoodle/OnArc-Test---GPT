import 'dart:async';
import 'package:flutter/material.dart';
import 'day.dart';
import 'controller.dart';
import 'ring.dart';

void main()=>runApp(MaterialApp(title:'Daywell',debugShowCheckedModeBanner:false,
  theme:ThemeData.dark(useMaterial3:true).copyWith(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff9dbfae),brightness:Brightness.dark),scaffoldBackgroundColor:const Color(0xff141a19)),home:const Home()));
class Home extends StatefulWidget{const Home({super.key});@override State<Home> createState()=>_Home();}
class _Home extends State<Home> with WidgetsBindingObserver {
  final p=Planner();int page=0;String? selected,focus,error;DateTime now=DateTime.now();
  late Timer timer;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);p.addListener(refresh);start();timer=Timer.periodic(const Duration(seconds:5),(_)=>refresh());}
  void refresh(){if(mounted)setState(()=>now=DateTime.now());}
  Future<void> start()async{try{await p.load();}catch(e){if(mounted)setState(()=>error=e.toString());}}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)refresh();}
  @override void dispose(){timer.cancel();WidgetsBinding.instance.removeObserver(this);p.removeListener(refresh);p.dispose();super.dispose();}
  Future<void> act(Future<void> Function() f) async{try{await f();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  String time(int m)=>clock(m,p.military);
  Widget heading(String s)=>Padding(padding:const EdgeInsets.only(top:12,bottom:8),child:Text(s,style:Theme.of(context).textTheme.titleLarge));
  Widget button(String s,VoidCallback tap)=>OutlinedButton(onPressed:tap,child:Text(s,textAlign:TextAlign.center));
  Widget row(Arc a,{VoidCallback? tap})=>ListTile(contentPadding:EdgeInsets.zero,leading:Text(a.icon,style:TextStyle(color:Color(a.colour),fontSize:24)),title:Text(a.name),subtitle:Text('${time(a.start)} – ${time(a.end)}'),onTap:tap,selected:page==1&&a.id==selected);
  Future<void> edit(Arc a,{bool fresh=false})async{
    setState((){page=1;selected=fresh?null:a.id;});
    final result=await Navigator.push<Arc>(context,MaterialPageRoute(builder:(_)=>ArcForm(a,p.day,fresh,p.military)));
    if(result!=null)await act(()async{await p.save(p.day.put(result,edit:!fresh));selected=result.id;refresh();});
  }
  Future<void> pick()async{final a=await showModalBottomSheet<Arc>(context:context,builder:(ctx)=>SafeArea(child:ListView(shrinkWrap:true,children:[for(final a in presets)ListTile(title:Text('${a.icon}  ${a.name}'),onTap:()=>Navigator.pop(ctx,a))])));if(a!=null)place(a);}
  void place(Arc a){int start=a.start;
    if(p.day.arcs.any((b)=>start<b.end&&b.start<start+a.length)){start=0;for(final b in p.day.arcs){if(start+a.length<=b.start)break;start=b.end;}if(start+a.length>1440)start=a.start;}
    edit(a.place(start),fresh:true);
  }
  Future<bool> confirm(String msg)async=>await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:Text(msg),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Keep')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Continue'))]))??false;
  @override Widget build(BuildContext context){
    if(!p.ready)return Scaffold(body:Center(child:Text(error??'Opening Daywell…')));
    final minute=now.hour*60+now.minute, current=p.day.current(minute),next=p.day.next(minute);
    if(p.intro)return Scaffold(body:SafeArea(child:ListView(padding:EdgeInsets.all(p.watch?28:24),children:[heading('Welcome to Daywell'),Text(p.watch?'Receive your dial from the paired phone.':'Your whole day on one dial. Open the editor to make the sample day yours.'),button('Begin',()=>act(()=>p.setting('intro',false)))])));
    final chosen=p.day.arcs.where((a)=>a.id==selected).firstOrNull;
    final isFocused=focus!=null && focus=='${current?.id}:${now.year}-${now.month}-${now.day}';
    final items=<Widget>[];
    if(p.watch){
      if(isFocused){items.addAll([heading(current!.name),Text('${p.day.remaining(minute)} min left'),Text(current.notes),button('Leave focus',()=>setState(()=>focus=null))]);}
      else{items.addAll([heading('Now'),Text(current?.name??'Open time'),if(current!=null)Text('${p.day.remaining(minute)} min left'),heading('Next'),Text(next==null?'Open time':'${next.name} · ${time(next.start)}'),if(current!=null)button('Focus on arc',()=>setState(()=>focus='${current.id}:${now.year}-${now.month}-${now.day}')),button('Receive from phone',()=>act(p.sync)),...switches()]);}
    }else if(page==0){
      items.addAll([Ring(p.day,minute),heading(current==null?'Open time':'${current.icon}  ${current.name}'),if(current!=null)Text('${p.day.remaining(minute)} min left'),heading('Up next'),Text(next==null?'Open time':'${next.name} · ${time(next.start)}${next.start<=minute?" tomorrow":""}'),heading('Agenda'),for(final a in p.day.arcs)row(a)]);
    }else if(page==1){
      items.addAll([Ring(p.day,minute,selected:selected,select:(a)=>setState(()=>selected=a.id),edit:edit,commit:(a)=>act(()=>p.save(p.day.put(a,edit:true)))),const Text('Drag an arc to move it. Drag a selected endpoint to resize. Hold to edit.'),button('Add arc',pick),if(chosen!=null)...[button('Edit ${chosen.name}',()=>edit(chosen)),button('Remove ${chosen.name}',()=>act(()=>p.save(p.day.remove(chosen.id))))],for(final a in p.day.arcs)row(a,tap:()=>setState(()=>selected=a.id)),if(p.day.arcs.isNotEmpty)button('Delete dial',()async{if(await confirm('Delete this dial and its arcs?'))await act(()=>p.save(Day.empty()));})]);
    }else if(page==2){
      items.addAll([heading('Your daily dial'),Text('${p.day.arcs.length} arcs'),button('Open editor',()=>setState(()=>page=1)),heading('Premade arcs'),for(final a in presets)ListTile(title:Text('${a.icon}  ${a.name}'),subtitle:Text('${a.length} min'),onTap:()=>place(a))]);
    }else{items.addAll([...switches(),button('Back up JSON',()=>act(p.export)),button('Restore JSON',()async{if(await confirm('Replace this dial from a backup?'))await act(p.import);}),button('Send to watch',()=>act(p.sync))]);}
    const names=['Today','Dial editor','Templates','Settings'];
    return Scaffold(appBar:p.watch?null:AppBar(title:Text(names[page]),actions:[PopupMenuButton<int>(tooltip:'Navigate',onSelected:(i)=>setState(()=>page=i),itemBuilder:(_)=>[for(int i=0;i<4;i++)PopupMenuItem(value:i,child:Text(names[i]))])]),body:SafeArea(child:ListView(key:ValueKey(p.watch?isFocused:page),padding:EdgeInsets.symmetric(horizontal:p.watch?32:20,vertical:p.watch?32:12),children:items)));
  }
  List<Widget> switches()=>[for(final pair in [('military','24-hour time',p.military),('nudges','Start nudges',p.nudges),('alarm','Use alarm sound',p.alarm)])SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(pair.$2),value:pair.$3,onChanged:pair.$1=='alarm'&&!p.nudges?null:(v)=>act(()=>p.setting(pair.$1,v)))];
}

class ArcForm extends StatefulWidget{
  final Arc arc;final Day day;final bool fresh,military;
  const ArcForm(this.arc,this.day,this.fresh,this.military,{super.key});
  @override State<ArcForm> createState()=>_FormState();
}
class _FormState extends State<ArcForm>{
  late final name=TextEditingController(text:widget.arc.name),notes=TextEditingController(text:widget.arc.notes),icon=TextEditingController(text:widget.arc.icon);
  late int start=widget.arc.start,end=widget.arc.end,colour=widget.arc.colour;String? error;
  @override void dispose(){name.dispose();notes.dispose();icon.dispose();super.dispose();}
  Future<void> choose(bool first)async{final m=(first?start:end)%1440;
    final t=await showTimePicker(context:context,initialTime:TimeOfDay(hour:m~/60,minute:m%60),builder:(c,w)=>MediaQuery(data:MediaQuery.of(c).copyWith(alwaysUse24HourFormat:widget.military),child:w!));
    if(t!=null)setState((){final n=t.hour*60+t.minute;if(first){start=n;}else{end=n==0?1440:n;}});
  }
  void finish(){try{final a=Arc(widget.arc.id,name.text.trim(),start,end,colour,icon.text.trim(),notes.text);widget.day.put(a,edit:!widget.fresh);Navigator.pop(context,a);}catch(e){setState(()=>error=e.toString());}}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.fresh?'Place arc':'Edit arc')),body:SafeArea(child:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:name,decoration:const InputDecoration(labelText:'Name')),TextField(controller:icon,decoration:const InputDecoration(labelText:'Icon')),
    ListTile(title:const Text('Start'),trailing:Text(clock(start,widget.military)),onTap:()=>choose(true)),ListTile(title:const Text('End'),trailing:Text(clock(end,widget.military)),onTap:()=>choose(false)),
    Wrap(spacing:4,children:[for(final a in presets)IconButton(tooltip:'${a.name} colour',icon:Icon(colour==a.colour?Icons.check_circle:Icons.circle,color:Color(a.colour)),onPressed:()=>setState(()=>colour=a.colour))]),
    TextField(controller:notes,maxLines:null,decoration:const InputDecoration(labelText:'Notes')),if(error!=null)Text(error!),FilledButton(onPressed:finish,child:const Text('Save arc'))
  ])));
}
