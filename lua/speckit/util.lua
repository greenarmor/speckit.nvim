local U = {}

function U.deep_merge(a, b)
  if type(a) ~= "table" then
    a = {}
  end
  if type(b) ~= "table" then
    return a
  end
  for k, v in pairs(b) do
    if type(v) == "table" and type(a[k]) == "table" then
      a[k] = U.deep_merge(a[k], v)
    else
      a[k] = v
    end
  end
  return a
end

return U
