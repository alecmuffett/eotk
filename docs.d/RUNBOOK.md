# Outcome

To recap, basically we are going to build one of these:

![softmap 4](https://raw.githubusercontent.com/alecmuffett/eotk/master/docs.d/softmap-4.png)

...for (in the given example configuration) Wikipedia.

# Systems

* Assume Ubuntu 16.04
* Assume 1x Balancer
  * eg: micro instance AWS, named "Brenda (the Balancer)"
* Assume 1+ Worker
  * eg: medium/large instance AWS, named "Wolfgang (the Worker)"
* You've only got a laptop / single machine?
  * Skim this document but go read the main README
    * experiment with `hardmap` which has less overhead/complication

# Install Process

* Install Ubuntu and EOTK on both Brenda and Wolfgang
  * as the `root` user - ON BOTH MACHINES
    * update all patches
    * set up for inbound SSH / systems administration, etc.
    * set up (if not already) a non-root user for EOTK purposes
      * possibly you can use a pre-existing non-root account like `ubuntu` or `www`
  * as the **non-root user** - ON BOTH MACHINES
    * Follow the EOTK Ubuntu Install Instructions at the following URL:
      * https://github.com/alecmuffett/eotk/blob/master/docs.d/HOW-TO-INSTALL.md
      * ...they are literally only three lines of cut and paste.
* Set up that Brenda can SSH to Wolfgang without passwords, as the non-root user
  * check that ssh works from brenda to wolfgang:
    * `ssh wolfgang uptime` # from brenda.  

# Configuration

These steps need to be done in a specific order:

* Change directory into the `eotk` directory
  * `cd eotk`
* Create a `site.tconf` file in the `eotk` directory
  * See the Wikipedia site config for an example that you can copy:
    * https://github.com/alecmuffett/eotk/blob/master/demo.d/wikipedia.tconf
* Do the following to create the onion keys and NGINX/Tor configuration files:
  * `eotk config site.tconf`
  * **NOTE:** You may want to take a moment to review the content of the generated `site.conf` (note new name) before progressing to the next step.
  * **SUGGESTION:** you may want to delete or rename `site.tconf` (note old name) at this point, to reduce confusion and/or risk of editing the wrong file in the future.
* Do the following to tell Brenda about Wolfgang the Worker:
  * `echo wolfgang > eotk-workers.conf` 
  * ...or edit the file, one hostname per line
* Do the following to push the configurations to the workers
  * `eotk ob-remote-nuke-and-push`
  * **NOTE:** This is a destructive push. You do **not** want to run this command whilst "live" workers are listed in `eotk-workers.conf`, to do so would impact user service in a bad (although recoverable) way.

# Test and Launch

* Check that ssh works
  * `eotk ps` 
* Start the workers
  * This creates worker onions-addresses which are **essential** for the following steps
  * `eotk start -a` 
* Check the workers are running
  * `eotk status -a` 
* Start onionbalance :star:
  * This fetches the worker onion-addresses (via `ssh`) and creates the OnionBalance configs, and launches the daemon:
  * `eotk ob-start -a`
* Check mappings and status
  * `eotk ob-maps -a`
  * `eotk ob-status -a`

# Configuring EOTK to Launch at Boot

Do this ON ALL MACHINES, because presumably you will want workers AND the balancer to autostart:

```
eotk make-init-script
sudo cp eotk-init.sh /etc/init.d/
sudo update-rc.d eotk-init.sh defaults
```

# Adding an Extra Worker ("William")

* Stop OnionBalance; don't worry, your service will keep working for several hours via Wolfgang
  * `eotk ob-stop` # this only affects Brenda
* Rename the existing eotk-workers.conf file
  * `mv eotk-workers.conf eotk-workers.conf,old`
* Create a new eotk-workers.conf, containing the new workers
  * `echo william > eotk-workers.conf`
  * feel free to edit/add more workers to this new file
* Push the configs to the new workers
  * `eotk ob-remote-nuke-and-push` 
  * **NOTE:** remember that this command is **destructive**, hence the rename of the old `eotk-workers.conf` file, so that Wolfgang is not affected / keeps your service up while you are doing this
* start the new workers
  * `eotk start -a` 
* check that the new workers are running
  * `eotk status -a` 
* *append* the old workers to the new list
  * `cat eotk-workers.conf,old >> eotk-workers.conf`
  * feel free to go sort/edit/prune `eotk-workers.conf` if you like
* re-start onionbalance, using the expanded list of all workers:
  * `eotk ob-start -a`
  * `eotk ob-maps -a`
  * `eotk ob-status -a`
* Don't forget to configure EOTK to "Launch at Boot" on William / the new servers
  * ...else sadness will result

# Removing a Worker ("Wolfgang")

Now that we have Wolfgang **and** William running, perhaps we want to decommission Wolfgang?

* Stop OnionBalance; don't worry, your service will keep working for several hours via William
  * `eotk ob-stop` # this only affects Brenda
* Backup the existing eotk-workers.conf file, in case of disaster
  * `cp eotk-workers.conf eotk-workers.conf,backup`
* Remove Wolfgang from `eotk-workers.conf`
  * use vi, emacs, nano, whatever
* Check that the remaining workers are all still running
  * `eotk status -a` 
* Re-start onionbalance, using the reduced list of all workers:
  * `eotk ob-start -a`
  * `eotk ob-maps -a` # check this output to make sure Wolfgang is gone
  * `eotk ob-status -a`
* Wait until new descriptors are fully & recently pushed (see: `ob-status -a`)
* Wait a little longer as a grace period
* Switch off Wolfgang

# I've made a minor tweak to my configuration...

Say you've edited a `BLOCK` regular expression, or changed the number of Tor workers; you can push out a "spot" update to the configuration files at the minor risk of breaking your entire service if you've made a mistake - so, assuming that you don't make mistakes, do this:

* `eotk config site.conf` # on Brenda, to update the configurations
* `eotk --local syntax` # ignoring the workers, use NGINX locally to syntax-check the NGINX configs
* `eotk ob-nxpush` # replicate `nginx.conf` to the workers
* `eotk nxreload`
* `eotk ob-torpush` # replicate `tor.conf` to the workers
* `eotk torreload`
* `eotk ps` # check everything is still alive
* `eotk status -a` # check everything is still alive
* `eotk ob-status -a` # check everything is still alive

## Something's gone horribly wrong...

If you do make mistakes and have somehow managed to kill all your Tor daemons, all your NGINX daemons, or (amusingly) both, you should undo that change that you made and then:

* `eotk config site.conf` # on Brenda, to update the configurations
* `eotk --local syntax` # ignoring the workers, use NGINX locally to syntax-check the NGINX configs
* `eotk shutdown` # turn everything off
* `eotk ob-nxpush` # replicate `nginx.conf` to the workers
* `eotk ob-torpush` # replicate `tor.conf` to the workers
* `eotk start -a` # start worker daemons
* `eotk status -a` # check worker daemons are running
* `eotk ob-start -a` # start onionbalance; your site will gradually start to come back up
* `eotk ob-status -a` # check status of descriptor propagation

In the worst-case scenario you might want to replace the `ob-nxpush` and `ob-torpush` with a single `ob-remote-nuke-and-push`

# Wholesale Update of EOTK

Once you work out what's going on, and how EOTK works, you'll see a bunch of ways to improve on this; however if you want to update your entire EOTK setup to a new version the **safest** thing to do is to set up and test an entirely new balancer instance (Beatrice?) and entirely new workers (I am running out of W-names) that Beatrice manages.  

The goal will be to take Beatrice's deployment to **just-before** the point where OnionBalance is started, marked with a :star: above. Then:

* On Brenda, Stop OnionBalance
  * `eotk ob-stop` # this only affects Brenda, stops her pushing new descriptors
* On Beatrice, start OnionBalance
  * **CHECK:** you've already started & checked Beatrice's workers, yes? If so, then:
  * `eotk ob-start -a` 
* On Beatrice, check mappings and status
  * `eotk ob-maps -a`
  * `eotk ob-status -a`
  * ...etc

Wait for Beatrice's descriptors to propagate (...`eotk ob-status -a` + few minutes grace period) and if everything is okay, on Brenda you can do:

* `eotk shutdown` # which will further stop EOTK on all of Brenda's workers

Leave Brenda and her workers lying around for a couple of days in case you detect problems and need to swap back; then purge.

## What if this is way too much hassle for me?

If you are a lower-risk site and don't want to go through all this change control, and if you know enough about driving `git` to do your own bookmarking and rollbacks, you can probably get away with this sort of very-dangerous, very-inadvisable-for-novices, "nuke-it-from-orbit" trick on Brenda:

* `git pull` # see warning immediately below
* `eotk config site.conf` # generate fresh configurations
* `eotk shutdown` # your site will be down from this point
* `eotk ob-remote-nuke-and-push` # push the new configs, this will destroy worker key material
* `eotk start -a` # start worker daemons
* `eotk status -a` # check worker daemons are running
* `eotk ob-start -a` # start onionbalance; your site will gradually start to come back up
* `eotk ob-status -a` # check status of descriptor propagation

**WARNING:** - the EOTK trunk code changes rapidly.  You might want to seek a stable release bookmark or test a version locally before "diving-in" with a randomly-timed `git pull`, else major breakage may result.

# Backup?

Yes, assuming that there is enough disk space on Brenda, you might want to pull copies of all the configurations and logfiles on all the workers.  To do that:

* `eotk mirror` # to build a local mirror of all worker `eotk` installations
* `eotk backup` # to make a compressed backup of a fresh mirror, for archiving.

# A note regarding small configurations

The value of `tor_intros_per_daemon` is set to `3` by default, in the expectation that we will be using horizontal scaling (i.e.: multiple workers) to gain performance, and that some of the workers may be down at any given time.

Also EOTK configures a semi-hardcoded number of Tor daemons per worker, in order to try and get a little more cryptographic multiprocessing out of Tor. This value (`softmap_tor_workers`) is currently set to `2` and is probably *not* helpful to change; the tor daemon itself is generally not a performance bottleneck.

Overall, our theory is that if `N=6` workers have `M=2` tor daemons, each of which has `P=3` introduction points, then that provides a pool of `N*M*P=36` introduction points for OnionBalance to scrape and attempt to synthesise into a "production" descriptor for one of the public onions.

But if you are only using a single `softmap` worker then `N=1` and so `N*M*P` is `1*2*3=6`, which is kinda small; in no way are 6 introduction points inadequate for testing, but in production it does mean that basically all circuit setups for any given onion will be negotiated through only 6 machines on the internet at any given time; and that those 6 introduction points will be servicing *all* connection-setups for *all* of the onion addresses that you configure in a project. This could be substantial.

The current hard-limit cap for `P` / the number of introduction points in a descriptor is `10`, and OnionBalance uses a magic trick ("distinct descriptors") to effectively multiply *that* number by 6, and so (in summary) EOTK can theoretically support 60 introduction points for any given `softmap` Onion Address, which it constructs by scraping introduction points out of the pool of worker onions.

But if you only have one worker, then by default OnionBalance only has 6 introduction points to work with.

In such circumstances I might suggest raising the value of `P` (i.e.: `tor_intros_per_daemon`) to `8` or even `10` for single-worker configs, so that (`N*M*P=1*2*8=`) 16 or more introduction points exist, so that OnionBalance has a bit more material to work with; but a change like this is probably going to be kinda "faffy" unless you are rebuilding from a clean slate. It may also lead to temporary additional *lag* whilst the old introduction points are polled when a worker has "gone down", if you restart workers frewuently.

And/or/else, you could always add more workers to increase `N`.

## But what if my pool of introduction points exceeds 60?!?

That's fine; OnionBalance randomly samples from within that pool, so that (averaged over time) all of the introduction points will see *some* traffic; but don't push it too far because that would be silly and wasteful to no benefit.  For existing v2 onion addresses (16 characters long) the optimal size of `N*M*P` is probably "anywhere between 18-ish and 60-ish".

# Q&A

* What if I want `localhost` as part of the pool of workers?
  * see the "Softmap 3" diagram at https://github.com/alecmuffett/eotk/blob/master/docs.d/softmap-3.png
  * this works; do `echo localhost >> eotk-workers.conf`
    * if localhost/Brenda is the *only* machine, you don't really need a `eotk-workers.conf` file
  * the string `localhost` is treated specially by eotk, does not require ssh access
  * alternative: read the other documentation, use `hardmap`, skip the need for OnionBalance
* Why install NGINX (and everything else) on brenda, too?
  1. Orthogonality: it means all machines are the same, easy of reuse/debugging
  2. Architecture: you may want to use Brenda for testing/development via `hardmap` deployments
  3. Testing: you can use `eotk [--local] syntax -a` to sanity-check NGINX config files before pushing
* How many workers can I have?
  * in the default EOTK config, you may sensibly install up to 30 workers (Wolfgang, William, Walter, Westley...)
  * this is because Tor descriptor space will max-out at 60 daemons, and EOTK launches 2x daemons per worker
    * this is somewhat tweakable if it becomes really necessary
* How many daemons will I get, by default?
  * 2x Tor daemons per worker
    * this is configurable
  * `N` NGINX daemons per worker, where N = number of cores
    * this is configurable
* What are the ideal worker specifications?
  * probably machines with between 4 and 20 cores, with memory to match
  * large, fast local `/tmp` storage, for caching
  * fast networking / good connectivity
  * manually configure for `(num Tor daemons) + (num NGINX daemons) == (num CPU cores)`, approximately.
    * you probably only need 1 or 2 Tor daemons to provide enough traffic to any machine
