VERSIONS = 2.4.4 2.5.0
LIBIGLOO_VERSION=0.9.5

TARBALLS = $(foreach version,$(VERSIONS),icecast-$(version).tar.gz)
IMAGE = ghcr.io/libretime/icecast
ALPINE_TARGETS = $(addprefix alpine-,$(VERSIONS))

.DEFAULT_GOAL := build

.PHONY: all build alpine debian fedora ubuntu lfs-check checksum $(VERSIONS) $(ALPINE_TARGETS) $(DEBIAN_TARGETS) $(FEDORA_TARGETS) $(UBUNTU_TARGETS)

all: build alpine debian fedora ubuntu

lfs-check:
        @for tarball in $(TARBALLS); do \
                if [ ! -f "$$tarball" ]; then \
                        continue; \
                fi; \
                if sed -n '1p' "$$tarball" | grep -q '^version https://git-lfs.github.com/spec/v1$$'; then \
                        wget https://downloads.xiph.org/releases/icecast/$$tarball; \
                fi; \
        done

checksum:
		sha512sum --ignore-missing --check SHA512SUMS.txt

$(VERSIONS): $(TARBALLS) lfs-check checksum
        docker build \
                --file alpine.dockerfile \
                --pull \
                --tag $(IMAGE):main \
                --tag $(IMAGE):$@-alpine \
                --build-arg VERSION=$@ \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .
        docker build \
                --file debian.dockerfile \
                --pull \
                --tag $(IMAGE):main \
                --tag $(IMAGE):$@-debian \
                --build-arg VERSION=$@ \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .
        docker build \
                --file fedora.dockerfile \
                --pull \
                --tag $(IMAGE):main \
                --tag $(IMAGE):$@-fedora \
                --build-arg VERSION=$@ \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .
        docker build \
                --file ubuntu.dockerfile \
                --pull \
                --tag $(IMAGE):main \
                --tag $(IMAGE):$@-ubuntu \
                --build-arg VERSION=$@ \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .

build: $(VERSIONS)

alpine: $(ALPINE_TARGETS)

		$(ALPINE_TARGETS): $(TARBALLS) lfs-check checksum
        docker build \
                --file alpine.dockerfile \
                --pull \
                --tag $(IMAGE):$(@:alpine-%=%)-alpine \
                --build-arg VERSION=$(@:alpine-%=%) \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .

debian: $(DEBIAN_TARGETS)

		$(DEBIAN_TARGETS): $(TARBALLS) lfs-check checksum
        docker build \
                --file debian.dockerfile \
                --pull \
                --tag $(IMAGE):$(@:debian-%=%)-debian \
                --build-arg VERSION=$(@:debian-%=%) \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .

fedora: $(FEDORA_TARGETS)

		$(FEDORA_TARGETS): $(TARBALLS) lfs-check checksum
        docker build \
                --file fedora.dockerfile \
                --pull \
                --tag $(IMAGE):$(@:fedora-%=%)-fedora \
                --build-arg VERSION=$(@:fedora-%=%) \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .

ubuntu: $(UBUNTU_TARGETS)

		$(UBUNTU_TARGETS): $(TARBALLS) lfs-check checksum
        docker build \
                --file ubuntu.dockerfile \
                --pull \
                --tag $(IMAGE):$(@:ubuntu-%=%)-ubuntu \
                --build-arg VERSION=$(@:ubuntu-%=%) \
                --build-arg LIBIGLOO_VERSION=$(LIBIGLOO_VERSION) \
                .
