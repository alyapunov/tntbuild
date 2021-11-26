#!/usr/bin/env ./src/tarantool

local my = require('my')
local txn_proxy = require('txn_proxy')
stfu = true

local filename = 'rep.lua'
if arg[1] then filename = arg[1] end

local skiplines = nil
if arg[2] then skiplines = tonumber(arg[2]) end

local conf = {wal_mode='write', memtx_memory=1024*1024*1024, listen=3301}

local fio = require('fio')
local f = fio.open(filename)
local text = f:read()
local lines = string.split(text, '\n')

if lines[1] and string.startswith(lines[1], '#!') then
    table.remove(lines, 1)
end

if lines[1] and string.startswith(lines[1], 'box.cfg') then
    conf = loadstring('return ' .. string.sub(lines[1], 8))()
    table.remove(lines, 1)
elseif lines[1] and string.startswith(lines[1], '--! box.cfg') then
    local overconf = loadstring('return ' .. string.sub(lines[1], 12))()
    for k,v in pairs(overconf) do conf[k] = v end
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

reprun_current_line_no = 0

if skiplines then
   while skiplines > 0 do
       table.remove(lines, 1)
       skiplines = skiplines - 1
       reprun_current_line_no = reprun_current_line_no + 1
   end
else
    os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')
end
box.cfg(conf)

for _,line in ipairs(lines) do
    reprun_current_line_no = reprun_current_line_no + 1
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
    my.print(unpack(res))

    collectgarbage('collect')
end

require('console').start()
