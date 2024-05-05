defmodule Rlopzc.RateLimiter do
  @moduledoc """
  Rate-limiting functionality.
  """
  use Nebulex.Cache, otp_app: :rlopzc, adapter: Nebulex.Adapters.Replicated

  @type key :: term()
  @type seconds :: non_neg_integer()
  @type limit :: non_neg_integer()
  @type opt :: {:seconds, non_neg_integer()} | {:limit, non_neg_integer()}

  @doc """
  Checks if the given `key` is allowed within `seconds` and `limit` options.

  ## Examples

      iex> check_rate("my_ip_address", seconds: 60, limit: 5)
      :allow
  """
  @spec check_rate(key(), [opt()]) :: :allow | :deny
  def check_rate(key, opts) do
    seconds = Keyword.get(opts, :seconds, 60)
    limit = Keyword.get(opts, :limit, 10)

    case get(key) do
      count when is_nil(count) or count < limit ->
        increment_count(key, seconds)
        :allow

      _count ->
        :deny
    end
  end

  @spec increment_count(key(), seconds()) :: non_neg_integer()
  defp increment_count(key, seconds) do
    incr(key, 1, ttl: :timer.seconds(seconds))
  end
end
