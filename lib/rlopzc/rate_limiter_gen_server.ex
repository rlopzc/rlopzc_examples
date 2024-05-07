defmodule Rlopzc.RateLimiterGenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def check_rate(key, opts \\ []) do
    GenServer.call(__MODULE__, {:check_rate, key, opts})
  end

  # Callbacks

  def init(_state) do
    {:ok, %{}}
  end

  def handle_call({:check_rate, key, opts}, _from, state) do
    seconds = Keyword.get(opts, :seconds, 60)
    limit = Keyword.get(opts, :limit, 10)

    IO.inspect(state)

    {result, state} =
      Map.get_and_update(state, key, fn
        nil ->
          expires_at = DateTime.utc_now() |> DateTime.add(seconds, :second)
          {:allow, {1, expires_at}}

        {count, expires_at} ->
          if count < limit and DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
            {:allow, {count + 1, expires_at}}
          else
            # TODO: compare expiry
            if count >= limit do
              # disallow
              {:deny, {count, expires_at}}
            else
              expires_at = DateTime.utc_now() |> DateTime.add(seconds, :second)
              {:allow, {1, expires_at}}
            end
          end
      end)

    {:reply, result, state}
  end
end
