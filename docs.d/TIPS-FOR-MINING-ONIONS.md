# Tips when mining Onion Addresses

## For v3 onion addresses; updated 18 May 2021

Hello from Alec - and congratulations! You are setting up an Onion
site! And you want a vanity onion address! There is lots of software
out there that you can use to generate them!

## What do I use?

Some people mine onion addresses on local hardware for privacy and
safety, whilst others are happy to rent a GPU-based compute-heavy
instance from AWS, or similar.

I'm not going to make terribly strong software recommendations,
because it's a matter of what you have at your disposal already,
and what fits the hardware that you have access to.

In my case I have a small cluster of Raspberry Pi, and I use
[`mkp224o`](https://github.com/cathugger/mkp224o) for mining with them.
I compiled the code manually, using
[the instructions](https://github.com/cathugger/mkp224o/blob/master/README.md)
and
[the tuning instructions](https://github.com/cathugger/mkp224o/blob/master/OPTIMISATION.txt)
to build something suitable for me.

If you are looking for a really meaningful, long-prefix onion address
up front, you will have to expend a lot of money and CPU-time in order
to find one.  This is why the next section is really important in
order to get the most "bang for your buck".

## How do I best approach this challenge?

If you're setting up multiple onions for your site -- eg: if there is
one/more CDNs associated with your site, it is nice to set up vanity
onions for them, too; partly for "cute" but also to stop yourself
going crazy during debugging.

For instance, the (defunct, V2) NYT
onion was https://www.nytimes3xbfgragh.onion/ and their CDN
onion was https://graylady3jvrrxbe.onion/

Similarly there were
https://www.facebookcorewwwi.onion/ and
https://fbcdn23dssr3jqnq.onion/ for Facebook.

Ask yourself now: perhaps use your CDN Onion to reflect your own
history and site/brand culture?  Perhaps you can mine several onion
addresses at the same time, even speculatively?

Onion mining is a matter of luck and expensive resource, and
(counterintuitively?)  the rarest resource that you have, is time
as-measured by your wall clock.

Therefore, if you are mining onions for a lot of sites, the best
strategy is follows:

* Have breakfast and some tea or coffee. Try to get into a creative
  mood.  You are making an investment of time *now* to save yourself
  time and effort, later.

* Sit down, open a document, and try to think inclusively of EVERY
  POSSIBLE PREFIX THAT YOU MIGHT EVER FIND ACCEPTABLE at the start (or
  suffix, at the end) of your onion addresses, for all of your sites
  and CDNs, and write them all down. You may create 10, 20, or
  more. No ideas are bad ideas. Deduplicate them (e.g.: it's pointless
  to look for `nytimes` if you're already looking for anything
  beginning with `nyt`).  Each additional prefix is nearly zero-cost,
  compared to the days, weeks, or months of time that your computers
  will spend in grinding their way through cryptography.

* Configure your software to search for all of these, for all of your
  sites, simultaneously. Set it running. Make sure to configure
  options (or: wrap it in a shellscript) so that it runs 24x7, saving
  all the successful matches into the local filestore.

* If/when you think of yet another prefix, stop your software,
  configure the extra prefix, and start it running again. Save all of
  the successful matches, never throw anything away.

* When you are approaching ship-date, get all the relevant parties
  together (or just yourself) and grab some beer/wine and use `grep`
  to go looking for the best ones. Eyeball the whole list, if you can.

* You will be surprised -- especially if you've invested fully into
  choosing as many meaningful prefixes as possible -- because you're
  dealing with randomness here, and raw entropy is more creative than
  you'd ever imagine.

* There is also a vast amount of noise -- huge, enormous quantities of
  gibberish -- but that's okay, because (again) `storage+grep` is
  much cheaper than `encryption+wallclocktime`.

* When we mined the Facebook onion address, the search-patterns were
  `^(facebook|fbcdn|fbsbx|...)` and a few others all in a single
  pattern.  We drank beer and spent a few days deciding amongst the
  good ones.

* Similarly the pattern for the nytimes was
  `^(nytimes|nytcdn|nytwww|graylady|...)` and a few other potential
  prefixes, perhaps a dozen, all in one pattern; and I mined onion
  addresses for other sites at the same time, on the same hardware, in
  the same process.

* Why do it this way? In short, because encryption is relatively
  expensive, and string comparisons are really cheap. Every single
  candidate onion address that you generate, should be tested against
  everything that you can imagine ever looking for, otherwise it's a
  wasted opportunity.

* Ideally, make sure that you are thoroughly in control of the backups
  and storage of the machine upon which you are doing the mining; try
  to use an encrypted partition if you can.

* Ensure that you have proper controls over all media which ever
  receives a copy of the Onion address key.

Best of luck to you. :-)

## Converting your V3 onion addresses for EOTK

Tools like `mkp224o` save the keys they generate as three separate
files: `hs_ed25519_public_key`, `hs_ed25519_secret_key`, and
`hostname`; this is elegant but hard to manipulate, so EOTK creates
its own standard for storing v3 onion addresses in the `secrets.d`
folder.

If you are in a directory which contains the above-named three files,
you can run a helper shellscript by using a command, something like:

```
~/eotk/lib.d/rename-v3-keys-for-eotk-secrets.sh
```

...which will safely create TWO files:

* `someverylongonionaddressinvolvingalotofbase32characterss.v3pub.key`
* `someverylongonionaddressinvolvingalotofbase32characterss.v3sec.key`

...that can be moved into your `~/eotk/secrets.d/` folder, for EOTK to
use when you run `eotk config ...`

## War Stories and Problems When Mining Onions

A long time ago I mined a bunch of test onion addresses for the New
York Times, and I put a few into test deployment; and one of them did
not work, like, at all.  I had mined them all using Shallot on
Raspbian/Debian, and I had hundreds to pick from, but one of the nice
ones was something like `foofoofoofoofoo.onion`

Or, at least, Shallot had told me that the key *was* `foofoofoofoofoo`
-- but when I checked the `hostname` file in the relevant Tor config,
it said that the respective onion address was something else entirely
(eg: `barbarbarbarbar.onion`).  I thought: this is crazy, but I
tracked it all the way back to the miner, and (in short) the contents
of the file did not match what Shallot said it was.

`Shallot` had lied.

So if you mine Onion Addresses, beware, and always test them
thoroughly, especially **before** buying SSL Certificates which cite
them.

### The Technical Bit

For technical reasons[1] EOTK now manually recreates the expected,
rather than actual, `hostname` file during install; so it might not
reflect reality if your V2 onion keys are thusly afflicted - for
instance if your Onion site is 100% unreachable.

The way to test a **V2 Onion** address for this syndrome is to
`cd` into `projects.d/.../foofoofoofoofoo.d/` and then **remove**
the `hostname` file in that directory.

Then do:

* `eotk shutdown && eotk start -a`

...which will regenerate that file.  Check that it matches your
expectation, and if not, discard that vanity address and start over.

Interestingly it appears that this behaviour (contents of a
regenerated `hostname` file may not necessarily match expectation)
appears to be the norm for V3 onion addresses, presumably because
elliptic curve cryptography, hence why I manually generate the
hostname files in recent versions of EOTK.  I need to talk to Tor
more, to find out if I am misapprehending regarding this latter.
