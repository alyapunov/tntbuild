#!/usr/bin/env ./src/tarantool

os.execute('if [ ./so/so.c -nt ./echo.so ]; then ./buildso.sh ; fi')
os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')
local repmy = require('my')

local fio = require('fio')
local f = fio.open('rep.lua')
local lines = string.split(f:read(), '\n')
if #lines ~= 0 and string.sub(lines[1], 1, 2) == '#!'
    then table.remove(lines, 1)
end
for _,line in ipairs(lines) do
    print('>' .. line)
    --loadstring(line)()
    local eq = string.find(line, '=')
    local have_ret = false
    if eq ~= nil then
        local eqq = string.find(line, '==')
        local br1 = string.find(line, '(', 1, true)
        local br2 = string.find(line, '{', 1, true)
        local m = eqq
        if m == nil or (br1 ~= nil and br1 < m) then m = br1 end
        if m == nil  or (br2 ~= nil and br2 < m) then m = br2 end
        if m ~= nil and (m < eq) then have_ret = true end
    else
        have_ret = true
    end
    if have_ret then line = 'return ' .. line end
    local tmpf = loadstring(line)
    if string.lstrip(string.rstrip(line)) == 'return' then
    elseif have_ret then
        res = {pcall(tmpf)}
        table.remove(res, 1)
        repmy.print(unpack(res))
    else
        pcall(tmpf)
    end
    collectgarbage('collect')
end
