local function my_clean_dir()
    os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')
end

local function my_size(t)
    if type(t) ~= 'table' and not box.tuple.is(t) then return 0 end
    local count = 0;
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function my_max_id(thing, default)
    local res = default
    for id in pairs(thing) do
        if type(id) == 'number' and id > res then res = id end
    end
    return res
end

local function my_is_array(t)
    if box.tuple.is(t) then return true end
    if type(t) ~= 'table' then return false end
    local count = 0
    local max = 0;
    for k,v in pairs(t) do
        if type(k) ~= 'number' then return false end
        if k ~= math.floor(k) or k < 1 then return false end
        count = count + 1
        max = k > max and k or max
    end
    return count == max
end

local function my_tostring(...)
    local res = ''
    local args = {...}
    local main_first = true
    for _,x in pairs(args) do
        if main_first then main_first = false else res = res .. ', ' end
        if type(x) == 'string' then
            res = res .. '"' .. x .. '"'
        elseif type(x) == 'table' and not my_is_array(x) then
            res = res .. '{'
            local first = true
            for k,v in pairs(x) do
                if first then first = false else res = res .. ', ' end
                if type(k) == 'string' then
                    res = res .. k .. '=' .. my_tostring(v)
                else
                    res = res .. '[' .. my_tostring(k) .. ']' .. '=' .. my_tostring(v)
                end
            end
            res = res .. '}'
        elseif my_is_array(x) then
            res = res .. '{'
            local size = #x
            for i = 1,size do
                if i > 1 then res = res .. ', ' end
                res = res .. my_tostring(x[i])
            end
            res = res .. '}'
        else
            res = res .. tostring(x)
        end
    end
    return res
end

local function my_print(...)
    print(my_tostring(...))
end

local my_last_create_space = nil
local function my_create_space(...)
    local name = 'test'
    for i = 2,65536 do
        if box.space[name] == nil then break end
        name = 'test' .. i
    end
    my_last_create_space = box.schema.space.create(name, ...)
    return my_last_create_space
end

local function my_create_index(...)
    local name = 'test1'
    for i = 2,256 do
        if my_last_create_space.index[name] == nil then break end
        name = 'test' .. i
    end
    return my_last_create_space:create_index(name, ...)
end

local function my_fselect(sp_or_ind, ...)
    local t = sp_or_ind:select(...)
    local n = #t
    local max_width = 140
    local min_col_width = 5
    local s = box.space[sp_or_ind.space_id or sp_or_ind.id]
    local cols = #s:format()

    for i = 1,n do
        cols = math.max(cols, #t[i])
    end

    local names = {}
    for j = 1,cols do
        table.insert(names, s:format()[j] and s:format()[j].name or tostring(j))
    end

    local widths = {}
    local real_width = cols + 1
    for j = 1,cols do
        local width = names[j]:len()
        for i = 1,n do
            width = math.max(width, my_tostring(t[i][j]):len())
        end
        width = math.max(width, min_col_width)
        real_width = real_width + width
        table.insert(widths, width)
    end
    while (real_width > max_width) do
        local max_j = 1
        for j = 2,cols do
            if widths[j] >= widths[max_j] then max_j = j end
        end
        widths[max_j] = widths[max_j] - 1
        real_width = real_width - 1
    end
    local delim = '+'
    for j = 1,cols do
        delim = delim .. string.rep('-', widths[j]) .. '+'
    end
    delim = delim .. ' '

    local tos = function(x, n, mod)
        local tmp = mod and x or my_tostring(x)
        local str
        if tmp:len() <= n then
            local add = n - tmp:len()
            local add1 = math.floor(add/2)
            local add2 = math.ceil(add/2)
            str = string.rep(' ', add1) .. tmp .. string.rep(' ', add2)
        else
            str = tmp:sub(1, n)
        end
        return str:gsub("%s",string.char(0xC2) .. string.char(0xA0))
    end

    local res = {}

    local ins = function(t, mod)
        local str = '|'
        local tlen = #t
        for j = 1,cols do
            str = str .. tos(t[j], widths[j], mod) .. '|'
        end
        str = str .. ' '
        table.insert(res, str)
    end

    table.insert(res, delim)
    ins(names, true)
    table.insert(res, delim)
    for i = 1,n do
        ins(t[i], false)
    end
    table.insert(res, delim)
    return res
end

local function my_find_space(name)
    if name:sub(1, 1) ~= 's' then error('wrong usage') end
    local ind = 1
    if name ~= 's' then
        ind = tonumber(name:sub(2))
        if name ~= 's' .. ind then return nil end
    end
    local max_space_no = my_max_id(box.space, 0)
    for i = 512,max_space_no do
        if box.space[i] then ind = ind - 1 end
        if ind == 0 then
            return box.space[i]
        end
    end
    return nil
end

local function my_find_index(name)
    if name:sub(1, 1) ~= 'i' then error('wrong usage') end
    local sp_ind = 1
    local in_ind = 1
    if name:len() > 3 then return nil end
    if name:len() == 2 then
        in_ind = tonumber(name:sub(2))
        if name ~= 'i' .. in_ind then return nil end
    elseif name:len() == 3 then
        sp_ind = tonumber(name:sub(2, 2))
        in_ind = tonumber(name:sub(3, 3))
        if name ~= 'i' .. sp_ind .. in_ind then return nil end
    end
    local max_space_no = my_max_id(box.space, 0)
    for i = 512,max_space_no do
        if box.space[i] then sp_ind = sp_ind - 1 end
        if sp_ind == 0 then
            return box.space[i].index[in_ind - 1]
        end
    end
    return nil
end

local function my_init()
    if type(box.cfg) ~= 'table' then
        error('init must be called after box.cfg{}')
    end
    if not box.schema.space_mt['fselect'] then
        box.schema.space_mt['fselect'] = my_fselect
    end

    local t = getmetatable(_G)
    if not t then t = {} end
    local old_index = t.__index
    local new_index = function(self, key)
        if type(key) == 'string' then
            local res = nil
            if key:sub(1, 1) == '_' then
                res = box.space[key]
            elseif key:sub(1, 1) == 's' then
                res = my_find_space(key)
            elseif key:sub(1, 1) == 'i' then
                res = my_find_index(key)
            end
            if res then return res end
        end
        return old_index and old_index(self, key) or nil
    end
    t.__index = new_index
    setmetatable(_G, t)
end

local function my_joinable(fib)
    fib:set_joinable(true)
    return fib
end

return {
    clean_dir = my_clean_dir,
    size = my_size,
    max_id = my_max_id,
    is_array = my_is_array,
    tostring = my_tostring,
    print = my_print,
    create_space = my_create_space,
    create_index = my_create_index,
    fselect = my_fselect,
    joinable = my_joinable,
    init = my_init,
}
