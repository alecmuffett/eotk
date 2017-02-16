all:
	echo nope:

distclean:
	eotk ob-stop
	eotk stop -a
	rm -rf projects.d onionbalance.d
