all:
	echo nope:

lint:
	./lib.d/lint.pl templates.d/* | sort -k 2

clean:
	rm -rf configure*.log *~ */*~ */*/*~

distclean dist-clean: clean
	./eotk shutdown
	rm -rf projects.d onionbalance.d

test-ob-tor:
	@echo this should print: onion
	curl -x socks5h://127.0.0.1:9050/ https://www.facebookcorewwwi.onion/si/proxy ; echo ""
