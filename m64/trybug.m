function trybug()
  try
    reallytry()
  catch nL
    rethrow(nL)
  end
end

function reallytry()
  x=1;
  try
    y=x(2);  
  catch L
    rethrow(L)
  end
end