# ns8-prometheus

This module runs [Prometheus](https://prometheus.io/) as a rootless module.

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/prometheus:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "prometheus1", "image_name": "prometheus", "image_url": "ghcr.io/nethserver/prometheus:latest"}

## Configure

Let's assume that the prometheus instance is named `prometheus1`.
The instance starts automatically, the create-module will:
- generate a random URL to access prometheus
- start and configure the prometheus instance to scrape local node_exporter and loki metrics

HTTP to HTTPS redirect and Let's Encrypt certificate are disabled.

The module has no settings, so it has no UI: the cluster-admin page of
the instance shows a placeholder.

Send a test HTTP request to the prometheus backend service:

    source /home/prometheus1/.config/state/environment
    curl http://127.0.0.1/${PROMETHEUS_PATH}/

## Service Discovery

Prometheus implements Service Discovery through [Service Providers](https://nethserver.github.io/ns8-core/modules/service_providers/#service-providers), this allows prometheus to dynamically link to services that provide a valid prometheus metrics entrypoint.

Prometheus will listen for `service-prometheus-metrics-updated` event and look for the `srv/http/prometheus-metrics` key in order to fetch the configuration.

The configuration is a JSON string saved under the `config` key. Said JSON must be validate against a proper json validation file, the file is provided [here](https://raw.githubusercontent.com/NethServer/ns8-prometheus/event-job-listener/imageroot/bin/validation.json).

## Uninstall

To uninstall the instance:

    remove-module --no-preserve prometheus1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/prometheus:latest

The tests are made using [Robot Framework](https://robotframework.org/)
