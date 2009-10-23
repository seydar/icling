` FILE:    ops.x
` PURPOSE: test X operators
` USAGE:   >> xcom x/bools.x x/ints.x x/reals.x x/iffis.x x/doods.x x/rels.x x/ops.x

t := 0;
t := bools :=;    p := t;
t := ints :=;     p := p + t;
t := reals :=;    p := p + t;
t := iffis :=;    p := p + t;
t := doods :=;    p := p + t;
t := rels :=;     p := p + t;
  
passedOps := p

