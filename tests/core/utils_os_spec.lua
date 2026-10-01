describe("utils.os", function()
  local os_utils = require("utils.os")
  local process_os = os
  local original_date
  local original_time

  before_each(function()
    original_date = process_os.date
    original_time = process_os.time
  end)

  after_each(function()
    rawset(process_os, "date", original_date)
    rawset(process_os, "time", original_time)
  end)

  it("substitutes the POSIX seconds directive on every platform", function()
    local received_format
    rawset(process_os, "time", function()
      return 123456
    end)
    rawset(process_os, "date", function(format)
      received_format = format
      return "formatted:" .. format
    end)

    assert.equals("formatted:epoch=123456", os_utils.get_datetime("epoch=%s"))
    assert.equals("epoch=123456", received_format)
  end)
end)
