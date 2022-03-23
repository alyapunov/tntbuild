local my = require('my')

local function assert_equals(a, b)
    if not my.equal(a, b) then
        my.print(a, b)
    end
end

local function assert_error_msg_content_equals(msg, f)
    local succ,err = pcall(f)
    if succ or tostring(err) ~= msg then
        my.print(succ, tostring(err), msg)
    end
end

return {
    assert_equals = assert_equals,
    assert_error_msg_content_equals = assert_error_msg_content_equals,
}