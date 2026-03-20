function main()
  a=gets(0,0,0,0)
  sets(0,0,0,0,a+5)
  b=gets(0,0,0,0)
  if b~=a+5 then error('s_fail') end
  x=getd(0,0,0)
  setd(0,0,0,x+7)
  y=getd(0,0,0)
  if y~=x+7 then error('d_fail') end
end
