function main()
  execevent(100, 1, 2, 3)
  callevent(101)
  walkfromto(1,2,10,20)
  scenefromto(3,4,30,40)
  changescene(5, 11, 22)
  local b = getbattlenumber()
  local x = getbattlerolepro(2,1)
  putbattlerolepro(2,1,x+9)
  local y = getbattlerolepro(2,1)
  if y ~= x + 9 then error('brole_fail') end
end
