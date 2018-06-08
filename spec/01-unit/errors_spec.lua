_G.test = true
local errors = require "cassandra.errors"
local Errors = errors.errors
local error_mt = errors.error_mt
local build_err = errors.build_error

describe("Error", function()
  describe("build_error", function()
    it("should return an object with error_mt metatable", function()
      local Err = build_err("fixture", {info = "foo"})
      assert.equal("function", type(Err))

      local some_err = Err("bar")
      assert.same(error_mt, getmetatable(some_err))
      assert.equal("foo", some_err.info)
      assert.equal("fixture", some_err.type)
      assert.equal("bar", some_err.message)
    end)
    it("should attach additional values through meta", function()
      local Err = build_err("fixture", {
        info = "fixture error",
        meta = function(foo)
          return {foo = foo}
        end
      })

      local some_err = Err("bar")
      assert.equal("bar", some_err.foo)
    end)
  end)
  describe("error_mt", function()
    local Err = build_err("fixture", {info = "foo"})

    it("should have a __tostring metamethod", function()
      local some_err = Err("bar")
      assert.has_no_error(function()
        tostring(some_err)
      end)
      assert.equal("bar", tostring(some_err))
    end)
    it("should have a __concat metamethod", function()
      local some_err = Err("bar")
      assert.has_no_error(function()
        tostring(some_err.." test")
        tostring("test "..some_err)
      end)
      assert.equal("test bar", "test "..some_err)
      assert.equal("bar test", some_err.." test")
    end)
  end)
  describe("NoHostAvailableError", function()
    it("should accept a string message", function()
      local err = Errors.NoHostAvailableError("Nothing worked as planned")
      assert.equal("NoHostAvailableError", err.type)
      assert.equal("Nothing worked as planned", err.message)
    end)
    it("should accept a table", function()
      local err = Errors.NoHostAvailableError({["abc"] = "DOWN", ["def"] = "DOWN"})
      assert.equal("NoHostAvailableError", err.type)
      -- can't be sure in which order will the table be iterated over
      assert.truthy(string.match(err.message, "All hosts tried for query failed%. %l%l%l: DOWN%. %l%l%l: DOWN%."))
    end)
  end)
  describe("ResponseError", function()
    it("should accept an error code", function()
      local err = Errors.ResponseError(666, "big error", "nothing worked")
      assert.equal(666, err.code)
      assert.equal("[big error] nothing worked", err.message)
    end)
  end)
  describe("TimeoutError", function()
    it("should accept an error code", function()
      local err = Errors.TimeoutError("127.0.0.1")
      assert.equal("timeout for peer 127.0.0.1", err.message)
    end)
  end)
  describe("SharedDictError", function()
    it("should accept a string", function()
      local err = Errors.SharedDictError("no memory")
      assert.equal("no memory", err.message)
    end)
    it("should accept a second argument: shm name", function()
      local err = Errors.SharedDictError("no memory", "dict_name")
      assert.equal("dict_name", err.shm)
      assert.equal("shared dict dict_name returned error: no memory", err.message)
    end)
  end)
end)
