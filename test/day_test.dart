import 'package:flutter_test/flutter_test.dart';
import 'package:daywell/day.dart';
void main(){
  final a=presets.last.place(60);
  test('placement copies the arc and JSON preserves identity and fields',(){
    final b=presets.last.place(60);
    expect(b.id,isNot(a.id));
    final day=Day.empty().put(a);expect(Day.decode(day.encode()).arcs.single,a);
    expect(()=>day.arcs.clear(),throwsUnsupportedError);
  });
  test('adjacency works and conflicting edits leave source intact',(){
    final b=presets.last.place(a.end);final d=Day.empty().put(a).put(b);
    expect(()=>d.put(a.copyAt(60,b.start+1),edit:true),throwsFormatException);
    expect(d.current(a.end),b);expect(d.next(b.start),a);
    expect(d.remaining(65),25);expect(d.remove(a.id).arcs,[b]);
  });
  test('midnight snap chooses side, resize stops and movement preserves length',(){
    final b=presets.last.place(1400);
    expect(b.move(20).end,1440);expect(b.move(30).start,0);
    expect(b.resize(90,false).end,1440);expect(a.resize(-200,true).start,0);
    for(int delta=-3000;delta<3000;delta++){final v=b.move(delta);expect(v.length,b.length);expect(v.start,greaterThanOrEqualTo(0));expect(v.end,lessThanOrEqualTo(1440));}
  });
  test('rejects overlapping import, duplicate identity and invalid intervals',(){
    final d=Day.empty().put(a);expect(()=>d.put(a),throwsFormatException);
    expect(()=>a.copyAt(1400,30),throwsFormatException);
    final raw=d.encode().replaceFirst(']}',',${d.encode().split('[').last}');
    expect(()=>Day.decode(raw),throwsFormatException);
    expect(Day.decode(Day.empty().encode()).arcs,isEmpty);
  });
}
