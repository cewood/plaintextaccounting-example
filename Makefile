BEANFILE           = $(or $(shell printenv BEANFILE), main.bean)
DOCKER_INTERACTIVE = $(if $(shell printenv GITHUB_ACTIONS),-t,-it)
GIT_REVISION       = $(or $(shell printenv GIT_REVISION),$(shell git describe --match= --always --abbrev=7 --dirty))


.dockerimage: Dockerfile
	docker \
	  build \
	  -t beancount .
	touch .dockerimage

.PHONY: docker-do-%
docker-do-%: .dockerimage
	docker run \
	  --rm \
	  ${DOCKER_INTERACTIVE} \
	  -e BEANFILE=${BEANFILE} \
	  -v ${PWD}:/beans \
	  -p 8080:8080 \
	  -w /beans \
	  beancount \
	  make $*

.PHONY: bean-check
bean-check:
	bean-check ${BEANFILE}

.PHONY: bean-check-docker
bean-check-docker: docker-do-bean-check

.PHONY: bean-web
bean-web:
	bean-web \
	  --public \
	  --port 8080 \
	  ${BEANFILE}

.PHONY: bean-web-docker
bean-web-docker: docker-do-bean-web

.PHONY: bean-format
bean-format:
	bean-format ${BEANFILE}

.PHONY: bean-format-docker
bean-format-docker: docker-do-bean-format

.PHONY: bean-report
bean-report:
	bean-report ${BEANFILE} $(or ${CMD},balances)

.PHONY: bean-report-docker
bean-report-docker: docker-do-bean-report

.PHONY: fava
fava:
	fava \
	  --port 8080 \
	  --host 0.0.0.0 \
	  ${BEANFILE}

.PHONY: fava-docker
fava-docker: docker-do-fava

.PHONY: gen
gen:
	make -C bank_exports gen

.PHONY: gen-docker
gen-docker: docker-do-gen
