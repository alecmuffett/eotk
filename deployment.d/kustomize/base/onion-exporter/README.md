# onion-exporter

[Github Link](https://github.com/systemli/prometheus-onion-service-exporter)

## Note

This deployment includes a tor relay because we can't use the one in the onion site deployment due to how tor daemon
works with onion sites. It's one or the other, onion site or relay.

## Metrics

```text
# HELP onion_service_latency
# TYPE onion_service_latency gauge
onion_service_latency{address="7sk2kov2xwx6cbc32phynrifegg6pklmzs7luwcggtzrnlsolxxuyfyd.onion",name="website",type="http"} 1.167850077
onion_service_latency{address="jntdndrgmfzgrnupgpm52xv2kwecq6mt4njyu2pzoenifsmiknxaasqd.onion:64738",name="mumble",type="tcp"} 0.331070165
# HELP onion_service_up
# TYPE onion_service_up gauge
onion_service_up{address="7sk2kov2xwx6cbc32phynrifegg6pklmzs7luwcggtzrnlsolxxuyfyd.onion",name="website",type="http"} 1
onion_service_up{address="jntdndrgmfzgrnupgpm52xv2kwecq6mt4njyu2pzoenifsmiknxaasqd.onion:64738",name="mumble",type="tcp"} 1
```
