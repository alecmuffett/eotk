# Command List

## Flags

* `--local`: ignore the presence of `eotk-workers.conf` and operate
  upon local projects; used to administer projects running locally on
  a machine which might *also* be running onionbalance.
* `--remote`: functionally the same as `--local` but denotes remote
  execution on a worker; used to inhibit recursion and loops amongst
  worker machines, of A calls B calls A calls B ...

## Configuration

* `eotk config [filename]` # default `onions.conf`
  * *synonyms:* `conf`, `configure`
  * parses the config file and sets up and populates the projects
* `eotk maps projectname ...` # or: `-a` for all
  * prints which onions correspond to which dns domains
  * for softmap, this list may not show until after `ob-config` and `ob-start`
* `eotk harvest projectname ...` # or: `-a` for all
  * *synonyms:* `onions`
  * prints list of onions used by projects

## Onion Generation

* `eotk genkey`
  * *synonyms:* `gen`
  * generate an onion key and stash it in `secrets.d`

## Project Status & Debugging

* `eotk status projectname ...` # or: `-a` for all
  * active per-project status
* `eotk ps`
  * do a basic grep for possibly-orphaned processes
* `eotk debugon projectname ...` # or: `-a` for all
  * enable verbose tor logs
* `eotk debugoff projectname ...` # or: `-a` for all
  * disable verbose tor logs

## Starting & Stopping Projects

* `eotk start projectname ...` # or: `-a` for all
  * start projects
* `eotk stop projectname ...` # or: `-a` for all
  * stop projects
* `eotk restart projectname ...` # or: `-a` for all
  * *synonyms:* `bounce`, `reload`
  * stop, and restart, projects
* `eotk nxreload projectname ...` # or: `-a` for all
  * politely ask NGINX to reload its config files


## Starting & Stopping OnionBalance

* `eotk ob-start projectname ...` # or: `-a` for all, if applicable
  * *synonyms:*
* `eotk ob-restart projectname ...` # or: `-a` for all, if applicable
  * *synonyms:*
* `eotk ob-stop`
  * *synonyms:*
* `eotk ob-status`
  * *synonyms:*

## Configuring Remote Workers

* `eotk-workers.conf`
  * if not present, only `localhost` will be used
  * if present, contains one hostname per line, no comments
    * the label `localhost` is a hardcoded synonym for local activity
    * other (remote) systems are accessed via `ssh`, `scp` & `rsync`
* `eotk ob-remote-nuke-and-push`
  * *synonyms:*
* `eotk ob-nxpush`
  * *synonyms:*
* `eotk ob-torpush`
  * *synonyms:*
* `eotk ob-spotpush`
  * *synonyms:*

## Backing-Up Remote Workers

* eotk `mirror`
  * *synonyms:*
* eotk `backup`
  * *synonyms:*
