all: deps compile

VERSION=0.2.0

compile:
	go build

deps:
	go get

fmt:
	gofmt -s -w -l .

dist: rpm deb

rpm-deps:
	yum install -y ruby ruby-devel rubygems rpm-build make go git
	gem install fpm

rpm: compile
	mkdir -p obj/redhat/usr/bin
	mkdir -p obj/redhat/lib/systemd/system/
	install -m 0755 docker-volume-moosefs obj/redhat/usr/bin
	install -m 0644 docker-volume-moosefs.service obj/redhat/lib/systemd/system
	fpm -C obj/redhat --vendor MooseFS -m "contact@moosefs.com" -f \
			-s dir -t rpm -n docker-volume-moosefs \
			--after-install files/post-install-systemd --version ${VERSION} . && \
			rm -fr obj/redhat

deb-deps:
	sudo apt-get install -y gcc golang git make ruby ruby-dev
	gem install fpm

deb: compile
	mkdir -p obj/debian/usr/bin
	mkdir -p obj/debian/lib/systemd/system/
	install -m 0755 docker-volume-moosefs obj/debian/usr/bin
	install -m 0644 docker-volume-moosefs.service obj/debian/lib/systemd/system
	fpm -C obj/debian --vendor MooseFS -m "contact@moosefs.com" -f \
			-s dir -t deb -n docker-volume-moosefs \
			--version ${VERSION} . && \
			rm -fr obj/debian

clean:
	rm -fr obj *.deb *.rpm docker-volume-moosefs

plugin: compile
	mkdir -p plugin/rootfs
	docker build -t moosefs-plugin-build -f plugin/Dockerfile .
	docker create --name tmp moosefs-plugin-build
	docker export tmp | tar -x -C plugin/rootfs
	docker rm -vf tmp
	docker rmi moosefs-plugin-build

plugin-enable:
	docker plugin create moosefs/docker-volume-moosefs:$(VERSION) plugin
	docker plugin enable moosefs/docker-volume-moosefs:$(VERSION)

plugin-push: plugin plugin-enable
	docker plugin push moosefs/docker-volume-moosefs:$(VERSION)

.PHONY: clean rpm-deps deb-deps fmt deps compile plugin plugin-enable plugin-push
