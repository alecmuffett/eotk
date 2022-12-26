.PHONY: all lint test clean distclean dist-clean test-ob-tor test-gok docker-build docker-run docker-debug docker-kill docker-status docker-clean std-params

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

docker-build:
	docker build --tag eotk-image --progress=plain -f opt.d/Dockerfile .

docker-run:
	docker run -it --name eotk-container -u user --cap-drop=all -f opt.d/Dockerfile \
		-v `pwd`/lib.d:/opt/eotk/lib.d \
		-v `pwd`/templates.d:/opt/eotk/templates.d \
		-v `pwd`/${PROJECT}-${ENVIRONMENT}.tconf:/opt/eotk/${PROJECT}-${ENVIRONMENT}.tconf \
		eotk-image || true
	$(MAKE) docker-kill

docker-debug:
	docker run -it --name eotk-container -e ENVIRONMENT=${ENVIRONMENT} -e PROJECT:${PROJECT} -f opt.d/Dockerfile \
		-v `pwd`/lib.d:/opt/eotk/lib.d \
		-v `pwd`/templates.d:/opt/eotk/templates.d \
		-v `pwd`/${PROJECT}-${ENVIRONMENT}.tconf:/opt/eotk/${PROJECT}-${ENVIRONMENT}.tconf \
		eotk-image || true
	$(MAKE) docker-kill

docker-kill:
	docker kill eotk-container || true
	docker rm eotk-container || true

docker-status:
	docker images -a
	docker ps -a

docker-clean:
	docker system prune --volumes
	docker image prune -a
	$(MAKE) docker-status

##################################################################

std-perms:
	find . -type d | xargs chmod 755
	find . -type f | xargs chmod 644
	find . -type f -name "*.sh" | xargs chmod 755
	find . -type f -name "*.pl" | xargs chmod 755
	find . -type f -name "*.py" | xargs chmod 755
	chmod 755 eotk
