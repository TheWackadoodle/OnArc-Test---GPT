import 'dart:math';
import 'package:flutter/material.dart';
import 'day.dart';
import 'package:flutter/gestures.dart';

class Ring extends StatefulWidget {
  final Day day;
  final int now;
  final String? selected;
  final ValueChanged<Arc>? select,edit,commit;
  const Ring(this.day,this.now,{super.key,this.selected,this.select,this.edit,this.commit});
  @override State<Ring> createState()=>_Ring();
}
class _Ring extends State<Ring>{
  Arc? original,preview;
  int previous=0,travel=0,handle=0;
  bool blocked=false;
  int minute(Offset p,double size)=>(((atan2(p.dy-size/2,p.dx-size/2)+pi/2)/(2*pi)*1440).round())%1440;
  Arc? hit(Offset p,double size){
    final r=(p-Offset(size/2,size/2)).distance;
    if((r-size*.36).abs()>size*.085)return null;
    return widget.day.current(minute(p,size));
  }
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    final s=min(c.maxWidth,440.0);
    final drawing=CustomPaint(size:Size.square(s),painter:_Face(widget.day,widget.now,widget.selected,preview,blocked));
    return Center(child:Semantics(label:'24 hour agenda dial',child:widget.commit==null?drawing:GestureDetector(
      onTapUp:(g){final a=hit(g.localPosition,s);if(a!=null)widget.select!(a);},
      onLongPressStart:(g){final a=hit(g.localPosition,s);if(a!=null)widget.edit!(a);},
      dragStartBehavior:DragStartBehavior.down,
      onPanStart:(g){
        previous=minute(g.localPosition,s);travel=0;handle=0;
        original=hit(g.localPosition,s);
        final chosen=widget.day.arcs.where((a)=>a.id==widget.selected).firstOrNull;
        if(chosen!=null && ((g.localPosition-Offset(s/2,s/2)).distance-s*.36).abs()<s*.085){
          int distance(int a)=>((previous-a+720)%1440-720).abs();
          final tolerance=min(24,max(1,chosen.length~/3));
          if(distance(chosen.start)<=tolerance || distance(chosen.end)<=tolerance){
            original=chosen;handle=distance(chosen.start)<distance(chosen.end)?-1:1;
          }
        }
        if(original!=null)widget.select!(original!);
      },
      onPanUpdate:(g){final a=original;if(a==null)return;
        final m=minute(g.localPosition,s);
        travel+=(m-previous+720)%1440-720;previous=m;
        final next=handle==0?a.move(travel):a.resize(travel,handle<0);
        try{widget.day.put(next,edit:true);blocked=false;}on FormatException{blocked=true;}
        setState(()=>preview=next);
      },
      onPanEnd:(_){final a=preview;if(a!=null)widget.commit!(a);setState((){original=null;preview=null;blocked=false;});},
      onPanCancel:(){setState((){original=null;preview=null;blocked=false;});},child:drawing)));
  });
}
class _Face extends CustomPainter{
  final Day day;final int now;final String? selected;final Arc? preview;final bool blocked;
  _Face(this.day,this.now,this.selected,this.preview,this.blocked);
  @override void paint(Canvas c, Size size){
    final w=size.width,center=Offset(w/2,w/2),r=w*.36;
    final p=Paint()..isAntiAlias=true;
    Offset at(double m,double radius)=>center+Offset(cos(m*pi/720-pi/2),sin(m*pi/720-pi/2))*radius;
    p..color=const Color(0xff303a38)..style=PaintingStyle.stroke..strokeWidth=w*.103;
    c.drawCircle(center,r,p);
    for(final item in day.arcs){
      final a=preview?.id==item.id?preview!:item;
      p..style=PaintingStyle.stroke..strokeWidth=w*.103..color=blocked && preview==a?const Color(0xffea887e):Color(a.colour);
      c.drawArc(Rect.fromCircle(center:center,radius:r),a.start*pi/720-pi/2,a.length*pi/720,false,p);
      if(a.id==selected){p..style=PaintingStyle.fill..color=Colors.white;
        for(final m in [a.start,a.end]){c.drawCircle(at(m.toDouble(),r),w*.015,p);}
      }
    }
    for(int h=0;h<24;h++){
      p..color=const Color(0xff8b9791)..strokeWidth=1;
      c.drawLine(at(h*60.0,w*.425),at(h*60.0,w*(h % 3 == 0 ? 0.445 : 0.435)),p);
      if(h%3==0){
        final t=TextPainter(text:TextSpan(text:'$h',style:TextStyle(color:Colors.white70,fontSize:w*.037)),textDirection:TextDirection.ltr)..layout();
        t.paint(c,at(h*60.0,w*.475)-Offset(t.width/2,t.height/2));
      }
    }
    p..color=Colors.white..style=PaintingStyle.fill..strokeWidth=2.5;
    c.drawLine(center,at(now.toDouble(),w*.416),p);c.drawCircle(center,w*.012,p);
  }
  @override bool shouldRepaint(_Face old)=>day!=old.day||now!=old.now||selected!=old.selected||preview!=old.preview||blocked!=old.blocked;
}
