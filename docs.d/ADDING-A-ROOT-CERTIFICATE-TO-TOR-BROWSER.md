# Adding A Root CA Certificate To Tor Browser

* This is for development purposes only, you should not do this if you
  rely upon the anonymity of Tor.

## Update #3: 3 July 2019

* Now you have to disable OCSP too

## Update #2: 20 June 2019

* With recent updates to TorBrowser, the storage of local certificate
  roots is somewhat more complex, but can be performed as follows.
* Be aware: whilst you are configured like this, some
  privacy-protective aspects of TorBrowser are reduced or
  switched-off; ensure that you restore your browser to defaults
  before using it for privacy-protecting purposes.

## Installation Part 1

* open about:config
* click "I accept the risk!"
* search for "security.nocertdb" in the box provided
  * if the "value" field says "default"/"true", then:
  * double-click on it to make it "modified"/"false"
* search for "browser.privatebrowsing.autostart" in the box provided
  * if the "value" field says "default"/"true", then:
  * double-click on it to make it "modified"/"false"
* search for "security.ssl.enable_ocsp_stapling" in the box provided
  * if the "value" field says "default"/"true", then:
  * double-click on it to make it "modified"/"false"
* dismiss the about:config tab
* IMPORTANT: NOW RESTART TOR BROWSER

## Installation Part 2

* Open Menu > TorBrowser > Preferences > Privacy & Security
* scroll down to Security > Certificates
* uncheck Query OCSP responder servers to confirm the current validity of certificates
* click "View Certificates"
* select "Authorities" tab
* click "Import", select your "rootCA.pem" file, click "Open"
* Popup: ensure that "Trust this CA to identify websites" is ticked/enabled
* click "Ok"
* check that "mkcert development CA" now appears in the list of authorities
* navigate to the target URL

## Uninstalling

When you are eventually finished with your certificate:

* Uninstall/remove the certificate, using the same dialogues
* Reverse the about:config changes which you performed above
* IMPORTANT: RESTART TOR BROWSER
