a=getrole(0,0)
setrole(0,0,a+1)
b=getrole(0,0)
if b~=a+1 then error('api_fail') end
