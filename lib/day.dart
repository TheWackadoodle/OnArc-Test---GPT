import 'dart:convert';
import 'dart:math';

int bounded(int n, int min, int max) => n.clamp(min, max).toInt();
String newId() => List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();
String clock(int m, [bool military=true]) {
  if (m==1440) return military ? '24:00' : 'Midnight';
  final h=m~/60, mm=(m%60).toString().padLeft(2,'0');
  return military ? '${h.toString().padLeft(2,'0')}:$mm' : '${h%12==0?12:h%12}:$mm ${h<12?"AM":"PM"}';
}

class Arc {
  final String id, name, icon, notes;
  final int start,end,colour;
  Arc(this.id,this.name,this.start,this.end,this.colour,this.icon,this.notes){
    if(id.isEmpty || name.trim().isEmpty || icon.isEmpty || start<0 || end>1440 ||
        end<=start || colour<0xff000000 || colour>0xffffffff) {
      throw const FormatException('Check the name, colour and times.');
    }
  }
  int get length => end-start;
  Arc copyAt(int s,int e) => Arc(id,name,s,e,colour,icon,notes);
  Arc place(int s) => Arc(newId(),name,s,s+length,colour,icon,notes);
  Arc move(int delta) {
    final midpoint=(start+length/2+delta)%1440;
    final s=bounded((midpoint-length/2).round(),0,1440-length);
    return copyAt(s,s+length);
  }
  Arc resize(int delta,bool leading) => leading ? copyAt(bounded(start+delta,0,end-1),end)
      : copyAt(start,bounded(end+delta,start+1,1440));
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'start':start,'end':end,'colour':colour,'icon':icon,'notes':notes};
  factory Arc.read(dynamic j)=>Arc(j['id'] as String,j['name'] as String,j['start'] as int,j['end'] as int,j['colour'] as int,j['icon'] as String,j['notes'] as String);
  @override bool operator ==(Object other)=>other is Arc && id==other.id && name==other.name && start==other.start && end==other.end && colour==other.colour && icon==other.icon && notes==other.notes;
  @override int get hashCode=>Object.hash(id,name,start,end,colour,icon,notes);
  @override String toString()=>'$icon $name · ${clock(start)} to ${clock(end)}';
}

final presets=[
  Arc('rest','Rest',0,420,0xff889ac5,'☾',''),
  Arc('breakfast','Breakfast',450,480,0xffd8b583,'☕',''),
  Arc('work','Work',540,720,0xff8dbbaa,'▦',''),
  Arc('lunch','Lunch',720,765,0xffdbad99,'◒',''),
  Arc('walk','Walk',1020,1050,0xffb4c993,'♧',''),
  Arc('guitar','Guitar',1140,1170,0xffc6a6cd,'♫','')
];
class Day {
  final List<Arc> arcs;
  Day._(List<Arc> list): arcs=List.unmodifiable(list);
  factory Day.empty()=>Day._([]);
  factory Day.sample()=>Day._([for(final p in presets)p.place(p.start)]);
  Day put(Arc a,{bool edit=false}) {
    if(arcs.any((b)=>b.id==a.id)!=edit) throw const FormatException('Arc identity conflict.');
    final rest=arcs.where((b)=>b.id!=a.id).toList();
    if(rest.any((b)=>a.start<b.end && b.start<a.end)) throw const FormatException('That time is already occupied.');
    return Day._([...rest,a]..sort((x,y)=>x.start.compareTo(y.start)));
  }
  Day remove(String id)=>Day._(arcs.where((a)=>a.id!=id).toList());
  String encode()=>jsonEncode({'version':1,'arcs':[for(final a in arcs)a.toJson()]});
  factory Day.decode(String raw){
    final obj=jsonDecode(raw);
    if(obj is! Map || obj['version']!=1 || obj['arcs'] is! List) throw const FormatException('Unknown plan format.');
    var day=Day.empty();
    for(final item in obj['arcs']){day=day.put(Arc.read(item));}
    return day;
  }
  Arc? current(int m)=>arcs.where((a)=>a.start<=m && m<a.end).firstOrNull;
  Arc? next(int m)=>arcs.where((a)=>a.start>m).firstOrNull ?? arcs.firstOrNull;
  int? remaining(int m){final a=current(m);return a==null?null:a.end-m;}
}
