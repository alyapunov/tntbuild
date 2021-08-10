#!/usr/bin/env ./src/tarantool

os.execute('if [ ./so/so.c -nt ./echo.so ]; then ./buildso.sh ; fi')
os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')
local repmy = require('my')
local txn_proxy = require('txn_proxy')
stfu = true

local fio = require('fio')
local f = fio.open('rep.lua')
local text = f:read()
local lines = string.split(text, '\n')
repmy.print('Are about to read ' .. #lines .. ' lines')

if #lines ~= 0 and string.sub(lines[1], 1, 2) == '#!' then
    table.remove(lines, 1)
end
local reslines = {}
local add = ''
for _,line in ipairs(lines) do
	line = string.rstrip(line)
	local line = add .. line
	add = ''
	if string.endswith(line, '\\') then
		line = string.sub(line, 1, string.len(line) - 1)
		line = string.rstrip(line)
		add = line .. '\n'
	elseif line ~= '' then
		table.insert(reslines, line)
	end
end
if add ~= '' then
	table.insert(reslines, add)
	add = ''
end
lines = reslines

for _,line in ipairs(lines) do
    print('>' .. line)

    local ignore,f,err1,err2 = pcall(loadstring, 'return ' .. line)
    if f == nil then
        ignore,f,err2 = pcall(loadstring, line)
    end
    if f == nil then
        print('fatal error in function parse')
        print('(1) ' .. tostring(err1))
        print('(2) ' .. tostring(err2))
        exit(-1)
    end

    local res = {pcall(f)}
    table.remove(res, 1)
    repmy.print(unpack(res))

    collectgarbage('collect')
end
