# Vattenfall

This is a very basic Prometheus exporter for the Vattenfall electricity spot
prices in Sweden. You can explore the data on https://www.vattenfall.se/elavtal/elpriser/timpris-pa-elborsen/.

It'll export one metric, `energy_price_per_kwh` for each region:

```
# HELP energy_price_per_kwh Energy price per kWh for a region
# TYPE energy_price_per_kwh gauge
energy_price_per_kwh{country="SE",currency="SEK",region="SN1"} 0.4707
energy_price_per_kwh{country="SE",currency="SEK",region="SN2"} 0.4707
energy_price_per_kwh{country="SE",currency="SEK",region="SN3"} 0.4707
energy_price_per_kwh{country="SE",currency="SEK",region="SN4"} 0.4707
```

Data is cached for 30min in memory to not hammer Vattenfall each time you
scrape the collector (and their API is slow). Though energy prices are
fixed the day before, due to exchange rate fluctuations prices sometimes
update during the day.

## Usage

```
-output.file string
    write metrics to specified file (must have .prom extension)
-output.http string
    host:port to listen on for HTTP scrapes
-region value
    region to query for, SN1-4, can be passed multiple times
```

To run it as a Prometheus exporter that you can query over HTTP:

```sh
$ vattenfall -output.http=":9000" -region SN1 -region SN2 -region SN3 -region SN4
```

Please note that there's 2 endpoints `/metrics` which instruments the
collector itself, and `/prices` with the pricing info.

If you want to use it with the textfile collector, for example in an hourly cron:

```sh
$ vattenfall -output.file="/etc/prometheus/textfile/electricity.prom" -region SN1 -region SN2 -region SN3 -region SN4
```

Or to just get the values on the console:

```sh
$ vattenfall -region SN1 -region SN2 -region SN3 -region SN4
```

## Usage with Docker

Docker images for the available releases are available on Docker Hub - https://hub.docker.com/r/rvoitenko/vattenfall

To run it as a Prometheus exporter that you can query over HTTP:
```sh
$ docker run -p 9000:9000 rvoitenko/vattenfall -output.http=":9000" -region SN1 -region SN2 -region SN3 -region SN4
```

Or to just get the values on the console:
```sh
$ docker run rvoitenko/vattenfall -region SN1 -region SN2 -region SN3 -region SN4
```

## Integration with Prometheus/Grafana

Docker-compose snippet:
```yaml
version: '3.8'
services:
  vattenfall:
    image: rvoitenko/vattenfall
    ports:
      - '127.0.0.1:9000:9000'
    command: -output.http=:9000 -region=SN3 

  prometheus:
    image: prom/prometheus
    ports:
      - '127.0.0.1:9090:9090'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  grafana:
    image: grafana/grafana:9.1.6
    links:
      - vattenfall
      - prometheus
    ports:
      - '127.0.0.1:3000:3000'
```

You can use the following Prometheus configuration to scrape the exporter(prometheus.yml):

```yaml
global:
  scrape_interval: 30s
  scrape_timeout: 10s

scrape_configs:
  - job_name: vattenfall
    metrics_path: /prices
    static_configs:
      - targets:
          - 'vattenfall:9000'
```