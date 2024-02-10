# EOTK Kustomize App

This [kustomize](https://kustomize.io/) app provides a fully featured enterprise k8s deployment of EOTK with the following features:

* Core deployment of EOTK exposing a Service for metrics ports
* Nginx Prometheus exporter sidecar in core deployment
* Onion service Prometheus exporter deployment
* Various PodMonitors for nginx, tor daemon, and onion site reachability
* NetworkPolicies to isolate pods to address security concerns

## Deployment

Deployment has 3 replicas, with slow rollingUpdate strategy and a pod disruption budget to not be too disruptive. Your
mileage may vary, but 2-3 replicas should be fine. Deployment comes with liveliness/readiness probes defined.

This also sets the nginx cache as an `emptyDir` at 10GB. Adjust as needed, but know this isn't a CDN or intelligent
cache design (since it's using `emptyDir` it is wiped when the pod rolls).

Note: You **will** need to change the `eotk-on-k8s` image to a registry that contains your published image.

## Secrets

This examples uses a Vault CSI provider with a file mount to `/var/local/secrets`, so update to your particular flavor and
mount point, but notice the particular secrets and location these are expected inside the pod.

* Onion cert secrets - these are the ones generated from mkp224o or similar. Filename must be `<onionsite>.v3<pub/sec>.key`
* SSL/TLS cert - standard certs, you'll need the .cert and .pem. Again, filenames are important and must be `<onionsite-first-20-chars>-v3.<cert/pem>`

## ConfigMap

There are two ConfigMaps in play: `onion-exporter-configmap` and the kustomize generated `eotk-on-k8s-config`.

`onion-exporter-configmap` controls the behavior of the onion exporter (shocking). Of note here is the `targets` values, add
your onion sites you care about, and the `insecure_skip_ssl_verify` will be needed if you're using `mkcert` and don't have
CA backed certs yet.

`eotk-on-k8s-config` controls the env vars in the deployment, specifying which ENVIRONMENT you're in and also the shared secret
you can use as an added header to validate it came from our onion site proxy. You can move this shared secret to a proper secret
if you desire.

## NetworkPolicies

Network policies are used to isolate the traffic to/from the EOTK deployment to minimize blast radius to the rest of the cluster.
Working from top to bottom, the NetworkPolicies are additive:

* `default-deny` - basic DENY ALL to start
* `allow-dns` - you'll need to provide DNS, so depending on your setup, you may need more of these rules
* `allow-prometheus-scraping` - assumes you have a namespace `monitoring` that does the scraping
* `intra-namespace` - let EOTK talk to EOTK (this is for the prom exporters)
* `outbound-internet-traffic` - allow all outbound except for RFC1918 IPs

## Overlay Notes

This example deployment uses kustomize's overlay setup with a `prod` and `staging` setup. Adjust to suit your environment.
