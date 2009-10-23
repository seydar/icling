` FILE:     rels.x
` PURPOSE:  test assignment of relations

lo := 1.0;
hi := 2.0;

t := 0;                            ` tests passed

x := lo<hi;          if x  ? t:=t+1 fi;
x := lo<=hi;         if x  ? t:=t+1 fi;
x := lo<=hi&hi<=lo;  if ~x ? t:=t+1 fi;
x := lo>=hi;         if ~x ? t:=t+1 fi;
x := lo>hi;          if ~x ? t:=t+1 fi;
x := hi<lo;          if ~x ? t:=t+1 fi;
x := hi<=lo;         if ~x ? t:=t+1 fi;
x := hi>=lo;         if x  ? t:=t+1 fi;
x := hi>lo;          if x  ? t:=t+1 fi;

ilo := 1;
ihi := 2;

x := ilo<ihi;        if x  ? t:=t+1 fi;
x := ilo<=ihi;       if x  ? t:=t+1 fi;
x := ilo=ihi;        if ~x ? t:=t+1 fi;
x := ilo~=ihi;       if x  ? t:=t+1 fi;
x := ilo>=ihi;       if ~x ? t:=t+1 fi;
x := ilo>ihi;        if ~x ? t:=t+1 fi;
x := ihi<ilo;        if ~x ? t:=t+1 fi;
x := ihi<=ilo;       if ~x ? t:=t+1 fi;
x := ihi=ilo;        if ~x ? t:=t+1 fi;
x := ihi~=ilo;       if x  ? t:=t+1 fi;
x := ihi>=ilo;       if x  ? t:=t+1 fi;
x := ihi>ilo;        if x  ? t:=t+1 fi;

passedrels := t;
