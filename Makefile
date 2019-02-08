all:
	echo "make what?"

lint:
	echo checking for lint:
	./lib.d/lint.pl templates.d/* | sort -k 2
	echo checking for expression typos:
	./lib.d/lint-expressions.pl templates.d/*

test: lint
	( cd lib.d ; ./test-expand-template.sh )

clean:
	rm -rf configure*.log *~ */*~ */*/*~

distclean dist-clean: clean
	./eotk shutdown
	rm -rf projects.d onionbalance.d
	rm -f eotk-housekeeping.sh eotk-init.sh

test-ob-tor:
	@echo this should print: onion
	curl -x socks5h://127.0.0.1:9050/ https://www.facebookcorewwwi.onion/si/proxy ; echo ""

test-gok:
	env PATH=./opt.d:./lib.d:.:$$PATH ./lib.d/generate-onion-key.sh

##################################################################

docker-test:
	docker build --tag eotk-image opt.d
	docker run -it --cap-drop=all --name eotk-container eotk-image

docker-status:
	docker images -a
	docker ps -a

docker-clean:
	docker system prune --volumes
	docker image prune -a
	make docker-status
