#
# Commands
#

export GIT ?= git
export GO ?= go
export MKDIR_P ?= mkdir -p
export RM ?= rm -f
export SHA256SUM ?= shasum -a 256
export SHELLCHECK ?= shellcheck
export TAR ?= tar
export ZIP_M ?= zip -m

#
# Variables
#

export GOFLAGS ?=

PLUGIN_DIST_TARGETS ?= $(addprefix dist-bin-,darwin-amd64 windows-amd64 windows-386 linux-amd64 linux-386 linux-arm64 linux-arm freebsd-amd64 freebsd-386 freebsd-arm netbsd-amd64 netbsd-386 openbsd-amd64 openbsd-386 solaris-amd64)

#
#
#

PLUGIN_DIST_NAME := vault-plugin-aws
PLUGIN_DIST_VERSION ?= $(shell $(GIT) describe --tags --always --dirty)

ARTIFACTS_DIR := artifacts
BIN_DIR := bin
SCRIPTS_DIR := puppet-relay-scripts

#
# Targets
#

.PHONY: all
all: build

$(ARTIFACTS_DIR) $(BIN_DIR):
	$(MKDIR_P) $@

.PHONY: generate
generate:
	$(GO) generate ./...

.PHONY: build
build: generate $(BIN_DIR)
	$(GO) build $(GOFLAGS) -o $(BIN_DIR)/$(PLUGIN_DIST_NAME) ./builtin/logical/aws/cmd/aws

.PHONY: check
check: generate
	$(SCRIPTS_DIR)/check

.PHONY: test
test: generate
	$(SCRIPTS_DIR)/test

.PHONY: dist
dist: $(PLUGIN_DIST_TARGETS)

.PHONY: clean
clean:
	$(RM) -r $(ARTIFACTS_DIR)/
	$(RM) -r $(BIN_DIR)/

.PHONY: $(PLUGIN_DIST_TARGETS)
$(PLUGIN_DIST_TARGETS): export CGO_ENABLED := 0
$(PLUGIN_DIST_TARGETS): export GOFLAGS += -a
$(PLUGIN_DIST_TARGETS): export GOOS = $(word 1,$(subst -, ,$*))
$(PLUGIN_DIST_TARGETS): export GOARCH = $(word 2,$(subst -, ,$*))
$(PLUGIN_DIST_TARGETS): export LDFLAGS += -extldflags "-static"
$(PLUGIN_DIST_TARGETS): dist-bin-%: $(ARTIFACTS_DIR)
	$(SCRIPTS_DIR)/dist $(PLUGIN_DIST_NAME) $(PLUGIN_DIST_VERSION)
