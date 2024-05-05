defmodule Rlopzc.RateLimiterTest do
  use ExUnit.Case, async: true

  doctest Rlopzc.RateLimiter, import: true

  alias Rlopzc.RateLimiter

  describe "check_rate/2" do
    test "allows it" do
      assert :allow = RateLimiter.check_rate("my_ip", seconds: 10, limit: 5)
    end

    test "denyes it" do
      assert :allow = RateLimiter.check_rate("my_other_ip", seconds: 10, limit: 1)
      assert :deny = RateLimiter.check_rate("my_other_ip", seconds: 10, limit: 1)
    end
  end
end
