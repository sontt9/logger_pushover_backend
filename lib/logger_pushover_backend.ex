defmodule LoggerPushoverBackend do
  @moduledoc """
  """

  use GenEvent

  defstruct [
    format: nil,
    metadata: nil,
    level: nil,
    pushover_host: nil,
    pushover_token: nil,
    pushover_user: nil,
    pushover_title: nil,
    pushover_priority: nil,
  ]

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  defp configure(name, opts) do
    state = %{
      name: nil,
      format: nil,
      level: nil,
      metadata: nil,
      pushover_host: nil,
      pushover_token: nil,
      pushover_user: nil,
      pushover_title: nil,
      pushover_priority: nil,
    }

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level        = Keyword.get(opts, :level, :error)
    metadata     = Keyword.get(opts, :metadata, [])
    pushover_host    = Keyword.get(opts, :pushover_host)
    pushover_token    = Keyword.get(opts, :pushover_token)
    pushover_user     = Keyword.get(opts, :pushover_user)
    pushover_title    = Keyword.get(opts, :pushover_title)
    pushover_priority = Keyword.get(opts, :pushover_priority, -1)

    %{state | name: name,
        level: level,
        metadata: metadata,
        pushover_host: pushover_host,
        pushover_token: pushover_token,
        pushover_user: pushover_user,
        pushover_title: pushover_title,
        pushover_priority: pushover_priority,
    }
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, message, _timestamp, metadata}}, state) do
    if meet_level?(level, state.level) do
      log_event(level, message, metadata, state)
    end

    {:ok, state}
  end

  defp meet_level?(_lvl, nil), do: true
  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp log_event(level, message, metadata, state) do
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    body = ~s(token=#{state.pushover_token}&user=#{state.pushover_user}&title=#{state.pushover_title}&priority=#{state.pushover_priority}&message=#{message})
    HTTPoison.post(state.pushover_host, body, headers)
  end


end
