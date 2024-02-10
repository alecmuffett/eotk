# Proxying Debugging Notes (Docker only)

If you need to inspect traffic to troubleshoot certain site features that may be breaking when
introducing an onion site proxy ontop of it, the following instructions will be helpful.
This assumes a working docker image and [Burp Suite](https://portswigger.net/burp)

Note: [Standard docker proxying](https://docs.docker.com/network/proxy/) doesn't work because nginx
doesn't honor that config, so we'll need to get creative.

In our `nginx.conf.txt`, change our `proxy_pass` statement from:

  `proxy_pass "$scheme://${servernamesubdomain}%DNS_DOMAIN%$request_uri2";`

To:

  `proxy_pass "$scheme://<your local private IP>:8080$request_uri2";`

Where the `<your local private IP>` is some IP reachable by your docker image (likely 192.168.x.x or similar, but not
localhost or 127.0.0.1).

Over in Burp Suite, you'll need to enable the ["invisible proxy"](https://portswigger.net/burp/documentation/desktop/tools/proxy/invisible) option under Request Handling. This will have Burp figure out where to route things, but we still need to mess with
HTTPS, so download the `cacert.der` as usual from `http://localhost:8080` or [similar](https://portswigger.net/burp/documentation/desktop/external-browser-config/certificate)

Now we need to convert this DER formatted cert into one the OS is expecting, so:

```bash
openssl x509 -inform der -in cacert.der -out burp_cert.crt
```

With this .crt extension file, we can add it to our Dockerfile under `/usr/local/share/ca-certificates/burp.crt` and
`RUN update-ca-certificates` to have the OS pick it up. Note: this needs to be run as root, so do it **before** the `USER`
statement in the Dockerfile.

Now startup the docker image, navigate to your onionsite, and you should see the traffic in Burp. This is handy to troubleshoot
CORS issues, weird header behavior, and other issues that would be easier to tweak in-transit than reloading the docker image.
