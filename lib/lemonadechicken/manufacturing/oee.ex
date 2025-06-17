defmodule Lemonadechicken.Manufacturing.OEE do
  @moduledoc """
  Module for calculating OEE (Overall Equipment Effectiveness) metrics.
  Provides functions for calculating availability, performance, and quality.
  """

  alias Lemonadechicken.Manufacturing

  @doc """
  Calculates availability based on time trackers.
  Availability = Actual Run Time / Planned Production Time
  """
  def calculate_availability(trackers, total_time) when total_time > 0 do
    downtime =
      trackers
      |> Enum.filter(fn tracker ->
        tracker.status.status_type in [:down, :maintenance]
      end)
      |> Enum.reduce(0, fn tracker, acc ->
        end_time = tracker.end_time || DateTime.utc_now()
        acc + DateTime.diff(end_time, tracker.start_time, :second)
      end)

    ((total_time - downtime) / total_time * 100)
    |> Float.round(2)
  end

  def calculate_availability(_, _), do: 0.0

  @doc """
  Calculates performance based on production run data.
  Performance = (Total Parts / Operating Time) / Ideal Run Rate
  """
  def calculate_performance(trackers, run \\ nil)

  def calculate_performance(trackers, %Manufacturing.ProductionRun{} = run) do
    running_time =
      trackers
      |> Enum.filter(& &1.status.status_type == :running)
      |> Enum.reduce(0, fn tracker, acc ->
        end_time = tracker.end_time || DateTime.utc_now()
        acc + DateTime.diff(end_time, tracker.start_time, :second)
      end)

    case running_time do
      0 -> 0.0
      time ->
        ideal_parts_per_second = run.target_quantity / DateTime.diff(run.planned_end_time, run.planned_start_time, :second)
        actual_parts_per_second = run.actual_quantity / time

        (actual_parts_per_second / ideal_parts_per_second * 100)
        |> Float.round(2)
    end
  end

  def calculate_performance(trackers, _) when length(trackers) > 0 do
    # Fallback when no production run data is available
    # Assumes performance based on running time vs ideal running time
    total_time = Enum.reduce(trackers, 0, fn tracker, acc ->
      end_time = tracker.end_time || DateTime.utc_now()
      acc + DateTime.diff(end_time, tracker.start_time, :second)
    end)

    running_time =
      trackers
      |> Enum.filter(& &1.status.status_type == :running)
      |> Enum.reduce(0, fn tracker, acc ->
        end_time = tracker.end_time || DateTime.utc_now()
        acc + DateTime.diff(end_time, tracker.start_time, :second)
      end)

    case total_time do
      0 -> 0.0
      _ -> (running_time / total_time * 100) |> Float.round(2)
    end
  end

  def calculate_performance(_, _), do: 0.0

  @doc """
  Calculates quality based on production run data.
  Quality = Good Parts / Total Parts
  """
  def calculate_quality(%Manufacturing.ProductionRun{actual_quantity: actual} = run) when actual > 0 do
    good_parts = actual - (run.defect_count || 0)
    (good_parts / actual * 100)
    |> Float.round(2)
  end

  def calculate_quality(_), do: 0.0

  @doc """
  Calculates OEE metrics for a given time period.
  Returns a map with availability, performance, quality, and overall OEE.
  """
  def calculate_metrics(trackers, total_time, run \\ nil) do
    availability = calculate_availability(trackers, total_time)
    performance = calculate_performance(trackers, run)
    quality = calculate_quality(run)

    oee =
      case {availability, performance, quality} do
        {0.0, _, _} -> 0.0
        {_, 0.0, _} -> 0.0
        {_, _, 0.0} -> 0.0
        {a, p, q} -> Float.round(a * p * q / 10_000, 2)
      end

    %{
      availability: availability,
      performance: performance,
      quality: quality,
      oee: oee
    }
  end

  @doc """
  Calculates metrics over a time interval.
  Returns a list of metrics maps with timestamps.
  """
  def calculate_interval_metrics(trackers, machines_count, {start_time, end_time}, interval_minutes \\ 60) do
    interval_seconds = interval_minutes * 60
    intervals =
      Stream.iterate(start_time, & DateTime.add(&1, interval_seconds, :second))
      |> Stream.take_while(& DateTime.compare(&1, end_time) == :lt)
      |> Enum.map(fn interval_start ->
        interval_end = min_datetime(DateTime.add(interval_start, interval_seconds, :second), end_time)
        interval_trackers = trackers_in_interval(trackers, interval_start, interval_end)
        total_time = DateTime.diff(interval_end, interval_start, :second) * machines_count

        metrics = calculate_metrics(interval_trackers, total_time)
        Map.put(metrics, :timestamp, interval_start)
      end)

    # Ensure we have at least one data point
    case intervals do
      [] -> [%{timestamp: start_time, availability: 0.0, performance: 0.0, quality: 0.0, oee: 0.0}]
      intervals -> intervals
    end
  end

  # Gets time trackers that overlap with the given interval
  defp trackers_in_interval(trackers, start_time, end_time) do
    Enum.filter(trackers, fn tracker ->
      tracker_end = tracker.end_time || DateTime.utc_now()
      DateTime.compare(tracker.start_time, end_time) == :lt &&
        DateTime.compare(tracker_end, start_time) == :gt
    end)
  end

  defp min_datetime(dt1, dt2) do
    case DateTime.compare(dt1, dt2) do
      :lt -> dt1
      _ -> dt2
    end
  end
end
