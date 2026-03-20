function main()
  local n = getrolename(0)
  local i = getitemname(0)
  local m = getmagicname(0)
  local s = getsubmapname(0)
  local l = drawlength(n)
  if type(n)~='string' or type(i)~='string' or type(m)~='string' or type(s)~='string' then error('name_type') end
  if type(l)~='number' then error('len_type') end
end
