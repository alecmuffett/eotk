# Stuff To Consider / Implement

* 020-generate-init-script.sh
* does onionbalance-tor use opt.d/tor in preference, or not?
* eotk script: refactor so that there's a separate ob-start which does NOT call ob-gather
* consider downgrade of RPi scripts to 3.0.x series Tor
* revisit o2d methods in lua
  * make the case-insensitivity (a) work && (b) be optional
  * at the moment it does a case-insensitive match AND THEN a case-sensitive lookup in a dictionary
