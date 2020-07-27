# Security Advisory: Tor Browser Leaks Secure Cookies Into Insecure Backend Channels

v1.0 - Alec Muffett, 27 July 2020

## Audience

All users and operators of `.onion` websites, especially (but not limited to) sites containing "mixed content" HTTPS and HTTP.

## Impact

TorBrowser leaks "secure" cookies that were issued over HTTPS, into cleartext HTTP channels that may be observable by third parties in backend deployments.

## How to determine if you are impacted

### Site Users

* Contact your site operators to ask if they are impacted.

### Site Owners: Onion Services

Check all instances of `tor.conf` on your deployed systems; if there is a configuration line for port 80 that looks like one of the following:

```
HiddenServicePort 80 <ipaddress>
HiddenServicePort 80 <ipaddress>:<portnum>
HiddenServicePort 80 <hostname>
HiddenServicePort 80 <hostname>:<portnum>
```

Then you are at-risk, **unless** one of the following

1. the value of `<ipaddress>` is `127.0.0.1` or some other locally-bound IP address for the server that is running the tor daemon, or...
2. the `<hostname>` is `localhost`; I recommend that you do not trust other hostnames because of the risk of dynamic DNS name-resolution.

### Site Owners: Reverse Proxies, Load Balancers

You are also at risk if you operate a reverse proxy (e.g. EOTK) or a layer-7 load balancer which receives port 80 HTTP traffic from Tor via any means (e.g. a Unix domain socket) which you then pass onwards to the upstream website without modification and/or without putting in place some additional security infrastructure.

## Background

### Why we are seeing this behaviour

### Consequences of this behaviour

### Alternatives to this behaviour

## Tor mitigations for this risk

## Practical mitigations for this risk

### EOTK Users

### Other Onion-Site Operators

## Likely FAQs

### Does this mean that "The Dark Web" is broken?

### "Is this a NSA Backdoor", etc?

### Impact on "large" `.onion` sites