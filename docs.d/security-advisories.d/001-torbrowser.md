# Security Advisory: Tor Browser Leaks Secure Cookies Into Insecure Backend Channels

v1.0 - Alec Muffett, 27 July 2020

## Audience

All users and operators of `.onion` websites, especially (but not
limited to) sites containing "mixed content" HTTPS and HTTP.

## Impact

TorBrowser leaks "secure" cookies that were issued over HTTPS, into
cleartext HTTP channels that may be observable by third parties in
backend deployments.

## How to determine if you are impacted

### Site Users

* Contact your site operators to ask if they are impacted.

### Site Owners: Onion Services

Check all instances of `tor.conf` on your deployed systems; if there
is a configuration line for port 80 that looks like one of the
following:

```
HiddenServicePort 80 <ipaddress>
HiddenServicePort 80 <ipaddress>:<portnum>
HiddenServicePort 80 <hostname>
HiddenServicePort 80 <hostname>:<portnum>
```

Then you are at-risk, **unless** one of the following

1. the value of `<ipaddress>` is `127.0.0.1` or some other
   locally-bound IP address for the server that is running the tor
   daemon, or...
2. the `<hostname>` is `localhost`; I recommend that you do not trust
   other hostnames because of the risk of dynamic DNS name-resolution.

You are most likely to be at risk if hosting your environment in some
manner of "cloud" or "cloud-like" infrastructure, but you should
consider the following issues whether or not you use cloud hosting for
your onion site.

### Site Owners: Reverse Proxies, Load Balancers

You are also at risk if you operate a reverse proxy (e.g. EOTK) or a
layer-7 load balancer which receives port 80 HTTP traffic from Tor via
any means (e.g. a Unix domain socket) which is then passed onwards to
the upstream website without modification and/or without putting in
place some additional **TorBrowser-specific** security infrastructure.

## Background

### Why we are seeing this behaviour

TorBrowser, almost uniquely amongst web browsers, implements "onion
networking" as an alternative layer-3 transport similar to TCP/IP;
onion networking provides secure communications to a cryptographic
network address, in a manner similar to a layer-3 VPN or an
IPsec-protected TCP/IP connection.

In recent software changes that were made to address a series of
feature requests:

* https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/21537
* https://gitlab.torproject.org/legacy/trac/-/issues/23247
* https://gitlab.torproject.org/legacy/trac/-/issues/21952
* https://bugzilla.mozilla.org/show_bug.cgi?id=1382359

...TorBrowser made the novel architectural choice that "HTTPS" and
"Plain HTTP Over Onion" should be treated as much the same thing /
should share the same "first party isolation" properties, without
apparent regard to how the backend implementation might be shaped.

This means that "Secure Cookies" which were issued to the client over
a HTTPS channel, will by default be sent back to the same server via
both HTTPS-over-Onion (safe) and **also** via HTTP-over-Onion (novel,
unexpected, potentially risky).

### Consequences of this behaviour

The web relies upon "cookies" as small pieces of data that enable
websites to carry some form of "state" - for instance that an incoming
request belongs to a user who has previously authenticated.

For purposes of security, certain cookies (usually: authentication- or
identity-related) may be marked as "Secure" to prevent them being sent
over insecure plaintext HTTP channels.  Although (by a quirk) they may
be legitimately set over any channel, the "Secure" tag requires that
the cookies are only over **returned** to the server over HTTPS.

This behaviour is considered one of the fundamentals of web
architecture, such that many server deployments reasonably do not
bother to protect legacy plaintext HTTP connections because "no data
of any consequence will be sent to them by the browser".

Unfortunately with this change, TorBrowser has moved from being one
which implements a superset of connectivity, to one which instead has
"special needs" for deployment because it treats plaintext HTTP as a
secure channel on-par with HTTPS - which does not match the
assumptions upon which most websites are built.

[DIAGRAM GOES HERE]

If for instance a HTTPS-enabled website `foo.onion` issues a "Secure"
session cookie for the `foo.onion` domain, it typically will not
expect the client to return that cookie to the third-party CDN which
is hosted on plaintext HTTP at http://cdn.foo.onion/ which is accessed
via a reverse proxy "VIP" / virtual-IP-address that receives traffic
which arrives over port 80 of the `foo.onion` onion circuit.

However: with this change TorBrowser **in specific** will leak session
cookies to third-party CDN sites, which will traverse the `foo.onion`
virtual private cloud, if not the whole internet, in cleartext where
they may be logged and caprtured by state surveillance agencies if no
other.

This problem should be familiar to people who have seen the "SSL added
and removed here" slide from the Snowden files.


### Alternatives to this behaviour

The goal of this change was apparently to enable sites to be adapted
to issue secure cookies for the purposes of login / compatibility.


## Mitigations for this behaviour

### Mitigations proposed by Tor

### Practical Mitigations: EOTK Users

### Practical Mitigations: Other Onion-Site Operators

## Likely FAQs

### Does this mean that "The Dark Web" is broken?

### "Is this a NSA Backdoor", etc?

### Impact on "large" `.onion` sites
