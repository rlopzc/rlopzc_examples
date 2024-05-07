defmodule Rlopzc.RateLimiterGenServer do
  use GenServer
  # https://pspdfkit.com/blog/2022/rate-limiting-server-requests/?utm_source=pocket_reader

  @type key :: term()
  @type seconds :: non_neg_integer()
  @type limit :: non_neg_integer()
  @type opt :: {:seconds, non_neg_integer()} | {:limit, non_neg_integer()}

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec check_rate(key(), [opt()]) :: :allow | :deny
  def check_rate(key, opts \\ []) do
    GenServer.call(__MODULE__, {:check_rate, key, opts})
  end

  # Callbacks

  def init(_state) do
    schedule_clean_up()
    {:ok, %{}}
  end

  def handle_call({:check_rate, key, opts}, _from, state) do
    seconds = Keyword.get(opts, :seconds, 60)
    limit = Keyword.get(opts, :limit, 10)

    {result, state} =
      Map.get_and_update(state, key, fn
        nil ->
          expires_at = DateTime.utc_now() |> DateTime.add(seconds, :second)
          {:allow, {1, expires_at}}

        {count, expires_at} when count < limit ->
          {:allow, {count + 1, expires_at}}

        {_count, _expires_at} = tuple ->
          {:deny, tuple}
      end)

    {:reply, result, state}
  end

  def handle_info(:clean_expired_entries, state) do
    schedule_clean_up()
    now = DateTime.utc_now()

    {:noreply,
     Map.filter(state, fn {_key, {_count, expires_at}} ->
       DateTime.compare(expires_at, now) == :gt
     end)}
  end

  defp schedule_clean_up do
    Process.send_after(self(), :clean_expired_entries, 1_000)
  end
end
