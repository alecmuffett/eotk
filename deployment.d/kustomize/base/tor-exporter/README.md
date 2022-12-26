# tor-exporter

This sets up the PodMonitor as the main deployment contains the actual daemon/port (see `service.yaml`).

## Note

Tor has built-in prometheus metrics reporting starting in tor version 0.4.7.1-alpha. This is exposed via the `MetricsPort` and
`MetricsPortPolicy` values in tor's configuration `torrc` file. However, MetricsPortPolicy doesn't really allow anything besides
localhost, so instead we use our nginx to proxy our (prom scraper ip):8080/metrics -> 127.0.0.1:9035/metrics
