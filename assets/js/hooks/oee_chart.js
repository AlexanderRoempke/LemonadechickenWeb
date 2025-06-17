const OEEChart = {
  mounted() {
    this.chart = this.createChart();
    this.handleUpdate();
  },

  updated() {
    this.handleUpdate();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },

  handleUpdate() {
    const intervals = JSON.parse(this.el.dataset.intervals || "[]");
    const chartType = this.el.dataset.type || "line";

    const timestamps = intervals.map(i => new Date(i.timestamp));
    const oeeData = intervals.map(i => i.oee);
    const availabilityData = intervals.map(i => i.availability);
    const performanceData = intervals.map(i => i.performance);
    const qualityData = intervals.map(i => i.quality);

    this.updateChart(timestamps, oeeData, availabilityData, performanceData, qualityData, chartType);
  },

  createChart() {
    const ctx = this.el.getContext('2d');
    return new Chart(ctx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          {
            label: 'OEE',
            data: [],
            borderColor: 'rgb(99, 102, 241)', // Indigo-500
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            borderWidth: 2,
            tension: 0.1,
            fill: false
          },
          {
            label: 'Availability',
            data: [],
            borderColor: 'rgb(16, 185, 129)', // Emerald-500
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            borderWidth: 2,
            tension: 0.1,
            fill: false
          },
          {
            label: 'Performance',
            data: [],
            borderColor: 'rgb(245, 158, 11)', // Amber-500
            backgroundColor: 'rgba(245, 158, 11, 0.1)',
            borderWidth: 2,
            tension: 0.1,
            fill: false
          },
          {
            label: 'Quality',
            data: [],
            borderColor: 'rgb(14, 165, 233)', // Sky-500
            backgroundColor: 'rgba(14, 165, 233, 0.1)',
            borderWidth: 2,
            tension: 0.1,
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false
        },
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'hour',
              displayFormats: {
                hour: 'MMM D, HH:mm'
              }
            },
            title: {
              display: true,
              text: 'Time'
            }
          },
          y: {
            beginAtZero: true,
            max: 100,
            title: {
              display: true,
              text: 'Percentage'
            }
          }
        },
        plugins: {
          legend: {
            position: 'top'
          },
          tooltip: {
            mode: 'index',
            intersect: false
          }
        }
      }
    });
  },

  updateChart(timestamps, oeeData, availabilityData, performanceData, qualityData, chartType) {
    if (!this.chart) return;

    // Determine time unit based on the time range
    let timeUnit = 'hour';
    const range = timestamps[timestamps.length - 1] - timestamps[0];
    const days = range / (1000 * 60 * 60 * 24);

    if (days > 7) {
      timeUnit = 'day';
    } else if (days > 1) {
      timeUnit = 'hour';
    } else {
      timeUnit = 'minute';
    }

    // Update chart type if needed
    if (this.chart.config.type !== chartType) {
      this.chart.config.type = chartType;
    }

    // Update scales for time unit
    this.chart.options.scales.x.time.unit = timeUnit;

    // Update datasets
    this.chart.data.labels = timestamps;
    this.chart.data.datasets[0].data = oeeData;
    this.chart.data.datasets[1].data = availabilityData;
    this.chart.data.datasets[2].data = performanceData;
    this.chart.data.datasets[3].data = qualityData;

    // Update chart
    this.chart.update('none'); // Use 'none' mode for better performance
  }
};

export default OEEChart;
