all:
	echo nope:

lint:
	echo checking for directive typos:
	egrep -i '[ \t]%[_a-z]+(\s+)?$$' templates.d/nginx.*
	echo checking for lint:
	./lib.d/lint.pl templates.d/* | sort -k 2

test: lint
	( cd lib.d ; ./test-expand-template.sh )

clean:
	rm -rf configure*.log *~ */*~ */*/*~

distclean dist-clean: clean
	./eotk shutdown
	rm -rf projects.d onionbalance.d

test-ob-tor:
	@echo this should print: onion
	curl -x socks5h://127.0.0.1:9050/ https://www.facebookcorewwwi.onion/si/proxy ; echo ""
