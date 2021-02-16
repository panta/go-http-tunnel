GO = go
export GO111MODULE=on
export GOFLAGS= -mod=vendor

all: clean check test

.PHONY: clean
clean:
	@$(GO) clean -r

.PHONY: fmt
fmt:
	@$(GO) fmt ./...

.PHONY: check
check: .check-fmt .check-vet .check-lint .check-ineffassign .check-mega .check-misspell .check-vendor

.PHONY: .check-fmt
.check-fmt:
	@$(GO) fmt ./... | tee /dev/stderr | ifne false

.PHONY: .check-vet
.check-vet:
	@$(GO) vet ./...

.PHONY: .check-lint
.check-lint:
	@golint `go list ./...` \
	| grep -v /id/ \
	| grep -v /tunnelmock/ \
	| tee /dev/stderr | ifne false

.PHONY: .check-ineffassign
.check-ineffassign:
	@ineffassign ./

.PHONY: .check-misspell
.check-misspell:
	@misspell ./...

.PHONY: .check-mega
.check-mega:
	@megacheck ./...

.PHONY: .check-vendor
.check-vendor:
	@$(GO) mod verify

.PHONY: test
test:
	@echo "==> Running tests (race)..."
	@$(GO) test -cover -race ./...

.PHONY: get-deps
get-deps:
	@echo "==> Installing dependencies..."
	@$(GO) mod vendor

.PHONY: get-tools
get-tools:
	@echo "==> Installing tools..."
	@$(GO) get -u github.com/golang/lint/golint
	@$(GO) get -u github.com/golang/mock/gomock

	@$(GO) get -u github.com/client9/misspell/cmd/misspell
	@$(GO) get -u github.com/gordonklaus/ineffassign
	@$(GO) get -u github.com/mitchellh/gox
	@$(GO) get -u github.com/tcnksm/ghr
	@$(GO) get -u honnef.co/go/tools/cmd/megacheck

OUTPUT_DIR = build
OS = "darwin freebsd linux windows"
ARCH = "386 amd64 arm"
OSARCH = "!darwin/386 !darwin/arm !windows/arm"
GIT_COMMIT = $(shell git describe --always)

.PHONY: release
release: check test clean build package

.PHONY: build
build:
	mkdir -p ${OUTPUT_DIR}
	CGO_ENABLED=0 GOARM=5 gox -ldflags "-s -w -X main.version=$(GIT_COMMIT)" \
	-os=${OS} -arch=${ARCH} -osarch=${OSARCH} -output "${OUTPUT_DIR}/pkg/{{.OS}}_{{.Arch}}/{{.Dir}}" \
	./cmd/tunnel ./cmd/tunneld

.PHONY: build-local
build-local tunnel tunneld:
	$(GO) build ./cmd/tunnel
	$(GO) build ./cmd/tunneld

.PHONY: package
package:
	mkdir -p ${OUTPUT_DIR}/dist
	cd ${OUTPUT_DIR}/pkg/; for osarch in *; do (cd $$osarch; tar zcvf ../../dist/tunnel_$$osarch.tar.gz ./*); done;
	cd ${OUTPUT_DIR}/dist; sha256sum * > ./SHA256SUMS

.PHONY: publish
publish:
	ghr -recreate -u panta -t ${GITHUB_TOKEN} -r go-http-tunnel pre-release ${OUTPUT_DIR}/dist
