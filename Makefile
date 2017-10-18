GOPATH ?= $(shell go env GOPATH)

# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
  $(error Please set the environment variable GOPATH before running `make`)
endif

CURDIR := $(shell pwd)
path_to_add := $(addsuffix /bin,$(subst :,/bin:,$(CURDIR)/_vendor:$(GOPATH)))
export PATH := $(path_to_add):$(PATH)

PACKAGES  := $$(go list ./...| grep -vE "vendor")
FILES     := $$(find . -name "*.go" | grep -vE "vendor")
TOPDIRS   := $$(ls -d */ | grep -vE "vendor")

.PHONY: all check errcheck

all: check

check: errcheck
	go get github.com/golang/lint/golint

	@echo "vet"
	@ go tool vet -all -shadow *.go 2>&1 | awk '{print} END{if(NR>0) {exit 1}}'
	@echo "golint"
	@ golint ./... 2>&1 | grep -vE 'context\.Context|LastInsertId|NewLexer|\.pb\.go' | awk '{print} END{if(NR>0) {exit 1}}'
	@echo "gofmt (simplify)"
	@ gofmt -s -l -w $(FILES) 2>&1 | grep -v "parser/parser.go" | awk '{print} END{if(NR>0) {exit 1}}'

errcheck:
	go get github.com/kisielk/errcheck
	@ GOPATH=$(CURDIR)/_vendor:$(GOPATH) errcheck -blank $(PACKAGES) | grep -v "_test\.go" | awk '{print} END{if(NR>0) {exit 1}}'
