#!/usr/bin/env ./src/tarantool

os.execute('if [ ./so/so.c -nt ./echo.so ]; then ./buildso.sh ; fi')
os.execute('rm -rf *.snap *.xlog *.vylog ./512 ./513 ./514 ./515 ./516 ./517 ./518 ./519 ./520 ./521')

ffi = require('ffi')
log = require('log')
fiber = require('fiber')
netbox = require('net.box')
buffer = require('buffer')
fun = require('fun')
msgpackffi = require('msgpackffi')
txn_proxy = require('txn_proxy')
my = require('my')

--require('jit.dump').start('+tbisrmXaT', arg[0] .. '.jdump')

--box.cfg{wal_mode='none', memtx_memory=1024*1024*1024, listen=3301}
--box.cfg{wal_mode='write', memtx_memory=1024*1024*1024, listen=3301, log_level=7}
box.cfg{wal_mode='write', memtx_memory=1024*1024*1024, listen=3301, memtx_use_mvcc_engine=true, log_level=5}

txn_proxy = require('txn_proxy')

s = box.schema.space.create('test')
i1 = s:create_index('pk', {parts={{1, 'uint'}}})
i2 = s:create_index('sec', {parts={{2, 'uint'}}})

s2 = box.schema.space.create('test2')
i21 = s2:create_index('pk', {parts={{1, 'uint'}}})
i22 = s2:create_index('sec', {parts={{2, 'uint'}}})

tx1 = txn_proxy.new()
tx2 = txn_proxy.new()
tx3 = txn_proxy.new()

-- Simple read/write conflicts.
s:replace{1, 0}
tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx2('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:replace{1, 2}')
tx1:commit()
tx2:commit()
s:select{}

-- Simple read/write conflicts, different order.
s:replace{1, 0}
tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx2('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:replace{1, 2}')
tx2:commit() -- note that tx2 commits first.
tx1:commit()
s:select{}

-- Implicit read/write conflicts.
s:replace{1, 0}
tx1:begin()
tx2:begin()
tx1("s:update({1}, {{'+', 2, 3}})")
tx2("s:update({1}, {{'+', 2, 5}})")
tx1:commit()
tx2:commit()
s:select{}

-- Implicit read/write conflicts, different order.
s:replace{1, 0}
tx1:begin()
tx2:begin()
tx1("s:update({1}, {{'+', 2, 3}})")
tx2("s:update({1}, {{'+', 2, 5}})")
tx2:commit() -- note that tx2 commits first.
tx1:commit()
s:select{}
s:delete{1}

-- Conflict in secondary index.
tx1:begin()
tx2:begin()
tx1("s:replace{1, 1}")
tx2("s:replace{2, 1}")
tx1:commit()
tx2:commit()
s:select{}
s:delete{1}

-- Conflict in secondary index, different order.
tx1:begin()
tx2:begin()
tx1("s:replace{1, 2}")
tx2("s:replace{2, 2}")
tx2:commit() -- note that tx2 commits first.
tx1:commit()
s:select{}
s:delete{2}

-- TXN is send to read view.
s:replace{1, 1}
s:replace{2, 2}
s:replace{3, 3}
tx1:begin()
tx2:begin()

tx1("s:select{}")
tx2("s:replace{1, 11}")
tx2("s:replace{2, 12}")
tx2:commit()
tx1("s:select{}")
tx1:commit()

s:delete{1}
s:delete{2}
s:delete{3}

-- TXN is send to read view but tries to replace and becomes conflicted.
s:replace{1, 1}
s:replace{2, 2}
s:replace{3, 3}
tx1:begin()
tx2:begin()

tx1("s:select{}")
tx2("s:replace{1, 11}")
tx2("s:replace{2, 12}")
tx2:commit()
tx1("s:select{}")
tx1("s:replace{3, 13}")
tx1("s:select{}")
tx1:commit()

s:delete{1}
s:delete{2}
s:delete{3}

-- Use two indexes
s:replace{1, 3}
s:replace{2, 2}
s:replace{3, 1}

tx1:begin()
tx2:begin()
tx1("i2:select{}")
tx2("i2:select{}")
tx1("s:replace{2, 4}")
tx1("i2:select{}")
tx2("i2:select{}")
tx1("s:delete{1}")
tx1("i2:select{}")
tx2("i2:select{}")
tx1:commit()
tx2("i2:select{}")
tx2:commit()
i2:select{}

s:delete{2}
s:delete{3}

-- More than two spaces
s:replace{1, 1}
s:replace{2, 2}
s2:replace{1, 2}
s2:replace{2, 1}
tx1:begin()
tx2:begin()
tx1("s:replace{3, 3}")
tx2("s2:replace{4, 4}")
tx1("s:select{}")
tx1("s2:select{}")
tx2("s:select{}")
tx2("s2:select{}")
tx1:commit()
tx2:commit()
s:select{}
s2:select{}
s:truncate()
s2:truncate()

-- Rollback
s:replace{1, 1}
s:replace{2, 2}
tx1:begin()
tx2:begin()
tx1("s:replace{4, 4}")
tx1("s:replace{1, 3}")
tx2("s:replace{3, 3}")
tx2("s:replace{1, 4}")
tx1("s:select{}")
tx2("s:select{}")
tx1:rollback()
tx2:commit()
s:select{}
s:truncate()

-- Delete the same value
s:replace{1, 1}
s:replace{2, 2}
s:replace{3, 3}
tx1:begin()
tx2:begin()
tx1("s:delete{2}")
tx1("s:select{}")
tx2("s:select{}")
tx2("s:delete{2}")
tx1("s:select{}")
tx2("s:select{}")
tx1:commit()
tx2:commit()
s:select{}
s:truncate()

-- Delete and rollback the same value
s:replace{1, 1}
s:replace{2, 2}
s:replace{3, 3}
tx1:begin()
tx2:begin()
tx1("s:delete{2}")
tx1("s:select{}")
tx2("s:select{}")
tx2("s:delete{2}")
tx1("s:select{}")
tx2("s:select{}")
tx1:rollback()
tx2:commit()
s:select{}
s:truncate()

-- Stack of replacements
tx1:begin()
tx2:begin()
tx3:begin()
tx1("s:replace{1, 1}")
tx1("s:select{}")
s:select{}
tx2("s:replace{1, 2}")
tx1("s:select{}")
s:select{}
tx3("s:replace{1, 3}")
s:select{}
tx1("s:select{}")
tx2("s:select{}")
tx3("s:select{}")
tx1:commit()
s:select{}
tx2:commit()
s:select{}
tx3:commit()
s:select{}

s:drop()
s2:drop()

-- https://github.com/tarantool/tarantool/issues/5423
s = box.schema.space.create('test')
i1 = s:create_index('pk', {parts={{1, 'uint'}}})
i2 = s:create_index('sec', {parts={{2, 'uint'}}})

s:replace{1, 0}
s:delete{1}
collectgarbage()
s:replace{1, 1}
s:replace{1, 2 }

s:drop()

-- https://github.com/tarantool/tarantool/issues/5628
s = box.schema.space.create('test')
i = s:create_index('pk', {parts={{1, 'uint'}}})

s:replace{1, 0}
s:delete{1}
tx1:begin()
tx1("s:replace{1, 1}")
s:select{}
tx1:commit()
s:select{}

s:drop()

s = box.schema.space.create('test')
i = s:create_index('pk', {parts={{1, 'uint'}}})
s:replace{1, 0}

tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:select{1}')
tx2('s:replace{1, 2}')
tx1:commit()
tx2:commit()
s:select{}

s:drop()

s = box.schema.space.create('test')
i = s:create_index('pk')
s:replace{1}
collectgarbage('collect')
s:drop()

-- A bit of alter
s = box.schema.space.create('test')
i = s:create_index('pk')
s:replace{1, 1}
i = s:create_index('s', {parts={{2, 'unsigned'}}})
s:replace{1, 1, 2 }
s:select{}
s:drop()

-- Point holes
-- HASH
-- One select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='hash'})
tx1:begin()
tx2:begin()
tx2('s:select{1}')
tx2('s:replace{2, 2, 2}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- One hash get
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='hash'})
tx1:begin()
tx2:begin()
tx2('s:get{1}')
tx2('s:replace{2, 2, 2}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- Same value get and select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='hash'})
i2 = s:create_index('sk', {type='hash'})
tx1:begin()
tx2:begin()
tx3:begin()
tx2('s:select{1}')
tx2('s:replace{2, 2, 2}')
tx3('s:get{1}')
tx3('s:replace{3, 3, 3}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
tx3:commit()
s:select{}
s:drop()

-- Different value get and select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='hash'})
i2 = s:create_index('sk', {type='hash'})
tx1:begin()
tx2:begin()
tx3:begin()
tx1('s:select{1}')
tx2('s:get{2}')
tx1('s:replace{3, 3, 3}')
tx2('s:replace{4, 4, 4}')
tx3('s:replace{1, 1, 1}')
tx3('s:replace{2, 2, 2}')
tx3:commit()
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- Different value get and select but in coorrect orders
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='hash'})
i2 = s:create_index('sk', {type='hash'})
tx1:begin()
tx2:begin()
tx3:begin()
tx1('s:select{1}')
tx2('s:get{2}')
tx1('s:replace{3, 3, 3}')
tx2('s:replace{4, 4, 4}')
tx3('s:replace{1, 1, 1}')
tx3('s:replace{2, 2, 2}')
tx1:commit()
tx2:commit()
tx3:commit()
s:select{}
s:drop()

--TREE
-- One select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='tree'})
tx1:begin()
tx2:begin()
tx2('s:select{1}')
tx2('s:replace{2, 2, 2}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- One get
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='tree'})
tx1:begin()
tx2:begin()
tx2('s:get{1}')
tx2('s:replace{2, 2, 2}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- Same value get and select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='tree'})
i2 = s:create_index('sk', {type='tree'})
tx1:begin()
tx2:begin()
tx3:begin()
tx2('s:select{1}')
tx2('s:replace{2, 2, 2}')
tx3('s:get{1}')
tx3('s:replace{3, 3, 3}')
tx1('s:replace{1, 1, 1}')
tx1:commit()
tx2:commit()
tx3:commit()
s:select{}
s:drop()

-- Different value get and select
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='tree'})
i2 = s:create_index('sk', {type='tree'})
tx1:begin()
tx2:begin()
tx3:begin()
tx1('s:select{1}')
tx2('s:get{2}')
tx1('s:replace{3, 3, 3}')
tx2('s:replace{4, 4, 4}')
tx3('s:replace{1, 1, 1}')
tx3('s:replace{2, 2, 2}')
tx3:commit()
tx1:commit()
tx2:commit()
s:select{}
s:drop()

-- Different value get and select but in coorrect orders
s = box.schema.space.create('test')
i1 = s:create_index('pk', {type='tree'})
i2 = s:create_index('sk', {type='tree'})
tx1:begin()
tx2:begin()
tx3:begin()
tx1('s:select{1}')
tx2('s:get{2}')
tx1('s:replace{3, 3, 3}')
tx2('s:replace{4, 4, 4}')
tx3('s:replace{1, 1, 1}')
tx3('s:replace{2, 2, 2}')
tx1:commit()
tx2:commit()
tx3:commit()
s:select{}
s:drop()

-- https://github.com/tarantool/tarantool/issues/5972
-- space:count and index:count
s = box.schema.create_space('test')
i1 = s:create_index('pk')

tx1:begin()
tx1('s:replace{1, 1, 1}')
tx1('s:count()')
s:count()
tx1:commit()
s:count()

tx1:begin()
tx1('s:delete{1}')
tx1('s:count()')
s:count()
tx1:commit()
s:count()

s:replace{1, 0}
s:replace{2, 0}
tx1:begin()
tx1('s:delete{2}')
tx1('s:count()')
tx1('s:replace{3, 1}')
tx1('s:count()')
tx1('s:replace{4, 1}')
tx1('s:count()')
tx2:begin()
tx2('s:replace{4, 2}')
tx2('s:count()')
tx2('s:replace{5, 2}')
tx2('s:count()')
tx2('s:delete{3}')
tx1('s:count()')
tx2('s:count()')
s:count()
tx1:commit()
tx2:commit()

s:truncate()

i2 = s:create_index('sk', {type = 'hash', parts={2,'unsigned'}})

-- Check different orders
s:truncate()
tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx2('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:replace{1, 2}')
tx1:commit()
tx2:commit()

s:truncate()
tx1:begin()
tx2:begin()
tx2('s:select{1}')
tx1('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:replace{1, 2}')
tx1:commit()
tx2:commit()

s:truncate()
tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx2('s:select{1}')
tx2('s:replace{1, 2}')
tx1('s:replace{1, 1}')
tx1:commit()
tx2:commit()

s:truncate()
tx1:begin()
tx2:begin()
tx1('s:select{1}')
tx2('s:select{1}')
tx1('s:replace{1, 1}')
tx2('s:replace{1, 2}')
tx2:commit()
tx1:commit()

test_run:cmd("setopt delimiter ';'")
run_background_mvcc = true
function background_mvcc()
    while run_background_mvcc do
        box.space.accounts:update('petya', {{'+', 'balance', math.ceil(math.random() * 200) - 100}})
    end
end
test_run:cmd("setopt delimiter ''");

_ = box.schema.space.create('accounts', { format = {'name', 'balance'} })
_ = box.space.accounts:create_index('pk', { parts = { 1, 'string' } })
box.space.accounts:insert{ 'vasya', 0 }
box.space.accounts:insert{ 'petya', 0 }

fiber = require 'fiber'

tx1:begin()
tx1("box.space.accounts:update('vasya', {{'=', 'balance', 10}})")

tx2:begin()
tx2("box.space.accounts:update('vasya', {{'=', 'balance', 20}})")
tx2:commit()

fib = fiber.create(background_mvcc)
fib:set_joinable(true)
fiber.sleep(0.1)
run_background_mvcc = false
fib:join();

tx1:commit()
box.space.accounts:select{'vasya'}
box.space.accounts:drop()

s:drop()

-- https://github.com/tarantool/tarantool/issues/5515
s = box.schema.space.create('test')
i0 = s:create_index('pk', {parts={{1, 'uint'}}})
i1 = s:create_index('i1', {id = 10, type = 'tree', parts={{2, 'uint'}}})
i2 = s:create_index('i2', {id = 20, type = 'hash', parts={{2, 'uint'}}})
i3 = s:create_index('i3', {id = 30, type = 'bitset', parts={{3, 'uint'}}})
i4 = s:create_index('i4', {id = 40, type = 'rtree', parts={{4, 'array'}}})
s:replace{1, 1, 15, {0, 0}}
s:replace{1, 1, 7, {1, 1}}
s:replace{1, 2, 3, {2, 2}}
tx1:begin()
tx1('i1:select{2}')
tx1('i1:select{3}')
tx1('i2:select{2}')
tx1('i2:select{3}')
tx1('i3:select{3}')
tx1('i3:select{16}')
tx1('i4:select{2, 2}')
tx1('i4:select{3, 3}')
tx1:commit()
s:drop()

box.begin()
s = box.schema.space.create('test')
_ = box.space.test:create_index('pk')
box.space.test:replace({1,2,3})
tx1:begin()
tx1('s:replace{2,2,3}');
tx1('s:replace{3,2,3}');
tx1:commit()
box.space.test:truncate()
assert(box.space.test ~= nil)
box.rollback()
assert(box.space.test == nil)
collectgarbage()
assert(box.space.test == nil)

require('console').start()
