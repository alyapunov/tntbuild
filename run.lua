#!/usr/bin/env ./src/tarantool

os.execute('if [ ./so/so.c -nt ./echo.so ] || ! [ -f ./echo.so ]; then ./sorebuild.sh ; fi')
os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')

ffi = require('ffi')
fio = require('fio')
log = require('log')
fiber = require('fiber')
netbox = require('net.box')
clock = require('clock')
txn_proxy = require('txn_proxy')
my = require('my')

function gc() return collectgarbage('collect') end

--require('jit.dump').start('+tbisrmXaT', arg[0] .. '.jdump')

--box.cfg{wal_mode='none', memtx_memory=1024*1024*1024, listen=3301}
--box.cfg{wal_mode='write', memtx_memory=1024*1024*1024, listen=3301, log_level=7}
--box.cfg{wal_mode='write', memtx_memory=1024*1024*1024, listen=3301}
box.cfg{wal_mode='write', memtx_memory=1024*1024*1024, listen=3301, memtx_use_mvcc_engine=true}

my.init()

local engine = 'memtx'
my.create_space{engine = engine}
my.create_index{type='tree', parts={{1, 'uint'}}}
--my.create_index{type='hash', parts={{2, 'uint'}}}
--my.create_index{type='tree', parts={{2, 'uint', is_nullable=true}}}
--my.create_index{type='tree', parts={{2, 'uint'}}, unique=true}
--parts = {{field = "attributes", is_nullable = true, path = "name[*].key", type = "string"}}
--parts = {{field = 2, path = "[*].key", type = "string"}, {field = 2, path = "[*].name", type = "string"}}
--my.create_index{type='tree', parts=parts}

--require('strict').on()

tx1 = txn_proxy.new()
tx2 = txn_proxy.new()
tx3 = txn_proxy.new()
--tx1:begin() tx1("s:replace{1,1}") tx1:commit()

--s:replace{1, 1}



function bench_call_echo(...)  print(fiber.id(), "bench_call_echo", my.tostring(...)) return ... end
function test(...) my.print({...}) return 1, {2, 3}, 4 end

box.schema.user.grant('guest', 'execute', 'universe', nil, {if_not_exists=true})
box.schema.user.grant('guest', 'read,write', 'space', 'test', nil, {if_not_exists=true})
box.schema.user.grant('guest', 'read,write', 'universe', nil, {if_not_exists=true})

box.schema.func.create('echo', {language='C', if_not_exists=true})
box.schema.user.grant('guest', 'execute', 'function', 'echo')
-- unpack(unpack(conn:call('echo', {1, 2, 3})))
box.schema.func.create('vshard.storage.call', {language='C', if_not_exists=true})
box.schema.user.grant('guest', 'execute', 'function', 'vshard.storage.call')
-- unpack(unpack(conn:call('vshard.storage.call', {3500, 'read', 'bench_call_echo', {{1, 2, 3}}})))

conn = netbox.connect(box.cfg.listen)

--local s = conn.space[512]
--s:replace{12345, 'asd', false}

require('console').listen(3313)
require('console').start()

