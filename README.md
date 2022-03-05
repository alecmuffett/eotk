# The Enterprise Onion Toolkit
![banner image](docs.d/hello-onion-text.png)

## :warning: Important HTTPS-related Annoucement: March 2022 

I've landed a small breaking change in order to better-support HARICA as a certificate provider,
but also for better usability; this change impacts any project with a multi-onion
EV certificate from Digicert.

* v3 onion addresses used in pathnames are now truncated at 20 chars
  of onion, rather than 30 overall, to make shorter pathnames for unix
  domain sockets
* onion scratch-directory name changes:
  * was: `projects.d/tweep.d/abcdefghijklmnopqrstuvwxyza-v3.d/port-80.sock`
  * now: `projects.d/tweep.d/abcdefghijklmnopqrst-v3.d/port-80.sock`
  * this may mean some scratch directories are remade
* https certificate path-name changes
  * was: HTTPS certificate files used the full onion address
  * now: onion HTTPS certificates are now expected to be installed in
    per-onion-truncated-at-20 pathnames: e.g. for each ONIONADDRESS in
    PROJECTNAME:
    * `/projects.d/PROJECTNAME.d/ssl.d/ONIONADDRFIRST20CHAR-v3.onion.cert`
    * `/projects.d/PROJECTNAME.d/ssl.d/ONIONADDRFIRST20CHAR-v3.onion.pem`
  * this means that you may need to rename pre-existing certificate 
    `cert` and `pem` files after you update and reconfigure; 
    **if you fail to do this you will see "self-signed certificate" warnings**
* if you are using 'multi' certificates (such as some Digicert EV) where a
  single certificate contains all SubjectAltNames for 2+ onion
  addresses that are part of a single project:
  * do `set ssl_cert_each_onion 0` in the configuration, to re-enable
    multi cert handling
  * was: path would have been
    `projects.d/PROJECTNAME.d/ssl.d/PRIMARYONIONADDRESSWASHERE.pem`
  * now: multi-certificate now goes into the more generic/meaningful
    `projects.d/PROJECTNAME.d/ssl.d/PROJECTNAME.pem`

If you have any issues, please reach out to @alecmuffett on Twitter, or log an issue above.

## Primary Supported Platforms

* Ubuntu 20.04LTS, Latest Updates
* OSX Mojave with Homebrew, Latest Updates
* Raspbian Stretch/Stretch-Lite, Latest Updates

## Maillist / Group

General discussion mailllist: deployment, tweaks and tuning:

* mailto:eotk-users+subscribe@googlegroups.com (via email)
* https://groups.google.com/group/eotk-users/subscribe (via web)

NB: bugs should be reported through `Issues`, above.

### EOTK In the News

* Apr 2021 [The Intercept launches onionsite using EOTK](https://theintercept.com/2021/04/28/tor-browser-onion/)
* Oct 2020 [Brave browser launches onionsite using EOTK](https://brave.com/new-onion-service/)
* Oct 2019 [BBC News launches 'dark web' Tor mirror](https://www.bbc.co.uk/news/technology-50150981)
* Oct 2019 [BBC launches dark web news site in bid to dodge censors](https://www.cityam.com/bbc-launches-dark-web-news-site-in-bid-to-dodge-censors/)
* Oct 2019 [Tor blimey, Auntie! BBC launches dedicated dark web mirror site](https://www.theregister.co.uk/2019/10/24/beeb_launches_dedicated_dark_web_site/)
* Oct 2019 [BBC News heads to the dark web with new Tor mirror
](https://www.theverge.com/2019/10/24/20930085/bbc-news-dark-web-tor-the-onion-browser-secure-censorship)
* Jan 2018 [Volunteer Spotlight: Alec Helps Companies Activate Onion Services
](https://blog.torproject.org/volunteer-spotlight-alec-helps-companies-activate-onion-services)
* Nov 2017 [Un service Wikipedia pour le Dark Web a été lancé par un ingénieur en sécurité](https://www.developpez.com/actu/175523/Un-service-Wikipedia-pour-le-Dark-Web-a-ete-lance-par-un-ingenieur-en-securite-afin-de-contourner-la-censure-dans-certains-pays/)
* Nov 2017 [Δημιουργήθηκε σκοτεινή έκδοση της Βικιπαίδειας για ανθρώπους σε λογοκριμένα καθεστώτα](https://texnologia.net/dhmiourgithike-skoteinh-ekdosh-ths-wikipedia-gia-anthropous-se-logokrimena-kathestota/2017/11)
* Nov 2017 [A security expert built an unofficial Wikipedia for the dark web](https://www.engadget.com/2017/11/25/a-security-expert-built-an-unofficial-wikipedia-for-the-dark-web/)
* Nov 2017 [There’s Now a Dark Web Version of Wikipedia](https://motherboard.vice.com/en_us/article/7x4g4b/theres-now-a-dark-web-version-of-wikipedia-tor-alec-muffett)
* Oct 2017 [The New York Times is Now Available as a Tor Onion Service](https://open.nytimes.com/https-open-nytimes-com-the-new-york-times-as-a-tor-onion-service-e0d0b67b7482)
* Apr 2017 [This Company Will Create Your Own Tor Hidden Service](https://motherboard.vice.com/en_us/article/this-company-will-create-your-own-tor-hidden-service)
* Feb 2017 [New Tool Takes Mere Minutes to Create Dark Web Version of Any Site](https://motherboard.vice.com/en_us/article/new-tool-takes-mere-minutes-to-create-dark-web-version-of-any-site)

## Introduction

EOTK provides a tool for deploying HTTP and HTTPS onion sites to
provide official onion-networking presences for popular websites.

The result is essentially a "man in the middle" proxy; you should set
them up only for your own sites, or for sites which do not require
login credentials of any kind.

## Installation

Please refer to the [How To Install](docs.d/HOW-TO-INSTALL.md) guide,
and the other documents in [that folder](docs.d/).

## Help I'm Stuck!

Ping @alecmuffett on Twitter, or log an `Issue`, above.

## Important Note About Anonymity

The presumed use-case of EOTK is that you have an already-public
website and you wish to give it a corresponding Onion address.

A lot of people mistakenly believe that Tor Onion Networking is "all
about anonymity" - which is incorrect, since it also includes:

* extra privacy
* identity/surety of to whom you are connected
* freedom from oversight/network surveillance
* anti-blocking, and...
* enhanced integrity/tamperproofing

...none of which are the same as "anonymity", but all of which are
valuable qualities to add to communications.

Further: setting up an Onion address can provide less contention, more
speed & more bandwidth to people accessing your site than they would
get by using Tor "Exit Nodes".

If you set up EOTK in its intended mode then your resulting site is
almost certainly not going to be anonymous; for one thing your brand
name (etc) will likely be plastered all over it.

If you want to set up a server which includes anonymity **as well as**
all of the aforementioned qualities, you [want to be reading an
entirely different document,
instead](https://github.com/alecmuffett/the-onion-diaries/blob/master/basic-production-onion-server.md).

## Acknowledgements

EOTK stands largely on the experience of work I led at Facebook to
create `www.facebookcorewwwi.onion`, but it owes a *huge* debt to
[Mike Tigas](https://github.com/mtigas)'s work at ProPublica to put
their site into Onionspace through using NGINX as a rewriting proxy --
and that [he wrote the whole experience up in great
detail](https://www.propublica.org/nerds/item/a-more-secure-and-anonymous-propublica-using-tor-hidden-services)
including [sample config
files](https://gist.github.com/mtigas/9a7425dfdacda15790b2).

Reading this prodded me to learn about NGINX and then aim to shrink &
genericise the solution; so thanks, Mike!

Also, thanks go to Christopher Weatherhead for acting as a local NGINX
*sounding board* :-)

And back in history: Michal Nánási, Matt Jones, Trevor Pottinger and
the rest of the FB-over-Tor team.  Hugs.
