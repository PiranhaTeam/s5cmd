#
# This Makefile is used for development only.
# For installation, refer to the Installation section in README.md.
#

SRCDIR ?= .
GOROOT ?= /usr/local/go

PROJECT_NAME := s5cmd

SHELL := /bin/bash
PLATFORM := $(shell go env GOOS)
ARCH := $(shell go env GOARCH)
GOPATH := $(shell go env GOPATH)
GOBIN := $(GOPATH)/bin

default: all

all: fmt build

dist: generate all

fmt:
	find ${SRCDIR} ! -path "*/vendor/*" -type f -name '*.go' -exec ${GOROOT}/bin/gofmt -l -s -w {} \;

generate:
	${GOROOT}/bin/go generate ${SRCDIR}

build-old:
	${GOROOT}/bin/go build ${GCFLAGS} -ldflags "${LDFLAGS}" ${SRCDIR}

build: ## build for local testing
	go fmt ./...
	PROJECT_BUILD_PLATFORMS=$(PLATFORM) PROJECT_BUILD_ARCHS=$(ARCH) ./hack/build-all.bash
	cp ./release/$(PROJECT_NAME)-$(PLATFORM)-$(ARCH) $(PROJECT_NAME)

release:clean ## create release executables
	go fmt ./...
	./hack/build-all.bash

clean:
	rm -rf ./release
	rm ./$(PROJECT_NAME)

dep:
	@dep ensure

.PHONY: all dist fmt generate build clean

.NOTPARALLEL:
