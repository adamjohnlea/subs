# subs — build & distribution
#
# Day-to-day:   make build | make test | make run
# Sharing:      make zip    (quick, unsigned — recipient strips quarantine)
#               make dist   (signed + notarized .pkg — runs clean anywhere)
#
# The signed path needs an Apple Developer Program membership and three
# values filled in below (DEV_ID_APP, DEV_ID_INSTALLER, NOTARY_PROFILE).
# See INSTALL.md / the "how to get your Developer ID" notes for how to get them.

# ---- config -----------------------------------------------------------------

BIN_NAME      := subs
BUNDLE_ID     := com.adamjohnlea.subs
VERSION       := $(shell git describe --tags --always 2>/dev/null || echo 0.1.0)

# Fill these in once you have your certs (see the setup notes).
# Find the exact strings with:  security find-identity -v
DEV_ID_APP       ?= Developer ID Application: Adam Lea (S927NCGL3V)
DEV_ID_INSTALLER ?= Developer ID Installer: Adam Lea (S927NCGL3V)
# notarytool keychain profile name you created with `notarytool store-credentials`
NOTARY_PROFILE   ?= subs-notary

# ---- paths (derived) --------------------------------------------------------

RELEASE_BIN := .build/release/$(BIN_NAME)
DIST        := dist
STAGE       := $(DIST)/stage
PKG         := $(DIST)/$(BIN_NAME)-$(VERSION).pkg
ZIP         := $(DIST)/$(BIN_NAME)-$(VERSION)-arm64.zip

.DEFAULT_GOAL := help

# ---- everyday ---------------------------------------------------------------

.PHONY: release build
release: ## Build the optimized release binary
	swift build -c release
	@echo "Built $(RELEASE_BIN)  ($(shell lipo -archs $(RELEASE_BIN) 2>/dev/null))"
build: release

.PHONY: test
test: ## Run the unit tests
	swift test

.PHONY: run
run: ## Build and run subs from source
	swift run $(BIN_NAME)

.PHONY: clean
clean: ## Remove build + dist artifacts
	swift package clean
	rm -rf $(DIST)

# ---- quick share (unsigned) -------------------------------------------------

.PHONY: zip
zip: release ## Zip the raw binary to share with friends (they strip quarantine once)
	@mkdir -p $(DIST)
	@cp $(RELEASE_BIN) $(DIST)/$(BIN_NAME)
	@cd $(DIST) && zip -q $(BIN_NAME)-$(VERSION)-arm64.zip $(BIN_NAME) && rm $(BIN_NAME)
	@echo "Wrote $(ZIP)"
	@echo "Recipient runs once:  xattr -d com.apple.quarantine ./$(BIN_NAME)"

# ---- proper share (signed + notarized .pkg) --------------------------------

.PHONY: sign
sign: release ## Code-sign the binary with Developer ID + hardened runtime
	@test "$(DEV_ID_APP)" != "Developer ID Application: YOUR NAME (TEAMID)" \
		|| { echo "ERROR: set DEV_ID_APP in the Makefile first"; exit 1; }
	codesign --force --options runtime --timestamp \
		--sign "$(DEV_ID_APP)" $(RELEASE_BIN)
	codesign -dv --verbose=2 $(RELEASE_BIN) 2>&1 | grep -E 'Authority|TeamIdentifier|Signature|flags'

.PHONY: pkg
pkg: sign ## Build a signed installer .pkg (installs to /usr/local/bin)
	@test "$(DEV_ID_INSTALLER)" != "Developer ID Installer: YOUR NAME (TEAMID)" \
		|| { echo "ERROR: set DEV_ID_INSTALLER in the Makefile first"; exit 1; }
	@rm -rf $(STAGE) && mkdir -p $(STAGE)
	@cp $(RELEASE_BIN) $(STAGE)/$(BIN_NAME)
	pkgbuild --root $(STAGE) --install-location /usr/local/bin \
		--identifier $(BUNDLE_ID) --version $(VERSION) \
		--sign "$(DEV_ID_INSTALLER)" $(PKG)
	@echo "Wrote $(PKG)"

.PHONY: notarize
notarize: pkg ## Notarize the .pkg with Apple and staple the ticket
	xcrun notarytool submit $(PKG) --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple $(PKG)
	@echo "Notarized + stapled: $(PKG)"

.PHONY: dist
dist: notarize verify ## Full release: build -> sign -> pkg -> notarize -> staple -> verify
	@echo ""
	@echo "Ready to ship: $(PKG)"

.PHONY: verify
verify: ## Check Gatekeeper will accept the signed binary and pkg
	@echo "--- binary ---"
	@codesign --verify --strict --verbose=2 $(RELEASE_BIN) && echo "binary signature OK"
	@echo "--- pkg (if built) ---"
	@test -f $(PKG) && spctl -a -vvv --type install $(PKG) || echo "(no pkg built yet)"

# ---- meta -------------------------------------------------------------------

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
