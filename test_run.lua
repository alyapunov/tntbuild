local function abort(name)
    return function(inspector)
        print('test_run failed: unknown method ' .. name)
        os.exit(-1)
    end
end

local function get_cfg(inspector, cfg_name)
    if cfg_name == 'engine' then
        return 'memtx'
    else
        print('test_run:get_cfg failed: unknown option ' .. cfg_name)
        os.exit(-1)
    end
end

local function cmd(inspector, command)
    if command == 'restart server default' then
        local has_xdotool = os.execute('xdotool --version > /dev/null 2>&1') == 0

        local fio = require('fio')
        local ffi = require('ffi')
        ffi.cdef('int open(const char *name, int flags, int mode);')
        ffi.cdef('int close(int fd);')
        ffi.cdef('ssize_t read(int fd, void *buf, size_t count);')
        local buf = ffi.new('char[16384]')
        local file = ffi.C.open("/proc/self/status", 0, 0)
        local text_size = ffi.C.read(file, buf, 16384)
        ffi.C.close(file)
        local text = ffi.string(buf, text_size)
        local tracer_pid = string.match(text, "TracerPid:[ \t]*([0-9]+)[^0-9]")
        local is_gdb = tracer_pid and tracer_pid ~= '' and tracer_pid ~= '0'

        local bin = arg[-1]
        local args = "'" .. arg[0] .. "' '" .. arg[1] .. "' " .. tostring(reprun_current_line_no)
        local cmd = ''
        if is_gdb then
            --cmd = "gdb '" .. bin .. "' -ex 'run " .. args .. "'"
            cmd = "run " .. args
        else
            cmd = bin .. ' ' .. args
        end
        if has_xdotool then
            local ex = "xdotool type --args 1 \"" .. cmd .. "\" key KP_Enter"
            os.execute(ex)
        else
            print('xdotool was not found! run the following by your own:')
            print(cmd)
        end
        os.exit(0)
    else
        print('test_run:cmd failed: unknown command ' .. command)
        os.exit(-1)
    end
end

local function new()
    local res = {get_cfg = get_cfg, cmd = cmd}
    return setmetatable(res, {__index=function(t,name) return abort(name) end})
end

return {new = new}
