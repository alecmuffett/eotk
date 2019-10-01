#!/bin/sh

# During development / before paying for an expensive EV certificate,
# you will be using self-signed certificates which EOTK generates;
# this is a (rational) nuisance because they must be manually accepted
# for every individual website that they are used on, else browsers
# will not fetch the pages which use those certs.

# Therefore: copy and amend this script (written for macOS, but
# portable) to pre-load the /hello-onion/ URLs on each site, so you
# can get most (all?) of the certificate acceptance completed
# up-front.

# All of this hassle amazingly goes away when you obtain a real SSL
# certificate; that may sound obvious, but it's an amazing feeling
# when your test site suddenly starts behaving like the "real thing"

# Wikipedia demo-examples given: top 9 sites by article count + "www"

# put onion addresses here, amend as necessary:
WWW=qgssno7jk2xcr2sj # eg: onion for alec's wikipedia demo
CDN=dryq3lhewlotggod # eg: onion for alec's wikimedia demo

# hack through list of sites on onions...
while read onion sites ; do
    for site in $sites ; do
        # ...and open them individually, for test-cert acceptance.
        url="https://$site.$onion.onion/hello-onion/"
        echo $url
        open -a "TorBrowser" $url
        sleep 1
    done
done <<EOF
$WWW www
$WWW en ceb sv de fr nl ru it es
$CDN login meta upload
EOF
