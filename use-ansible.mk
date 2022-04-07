#!/usr/bin/make -f

MAKEFLAGS += -Rr --warn-undefined-variables

top: default

self    := $(lastword $(MAKEFILE_LIST))
$(self) := $(basename $(self))
$(self):;

# get various ansible versions

GIT_CLONE_BASE ?= /usr/local/ext
base := $(GIT_CLONE_BASE)
base.help := sudo mkdir $(base); sudo chmod g+w $(base)
$(and $(or $(wildcard $(base)),$(error you must create $(base) (e.g. "$(base.help)"))),)

last           := 2.13
stables.short  := 2.4 2.5 2.6 2.7 2.8 2.9 2.10 2.11 2.12 $(last)
stables        := 1.9 2.0 2.1 2.2 2.3 $(stables.short)
versions       := $(stables:%=stable-%) devel
versions.short := $(stables.short:%=stable-%) devel
version.last   := $(last:%=stable-%)

url := git://github.com/ansible/ansible.git

clone = (cd $(base) && test -d ansible-$(version) || git clone --branch $(version) --recursive $(url) ansible-$(version))
#pull  = (cd $(base)/ansible-$(version) && git pull --rebase && git submodule update --init --recursive)
pull  = (cd $(base)/ansible-$(version) && git fetch && (git diff --quiet @{upstream} || git pull --rebase && git submodule update --init --recursive))
setup = source $(base)/ansible-$(version)/hacking/env-setup -q
pkgs  = sudo aptitude install python-jinja2 python-netaddr
emacs  = (progn
emacs +=   (setenv "ANSIBLE_HOME" (expand-file-name "$(base)/ansible-$(version)"))
emacs +=   (setenv "PYTHONPATH" (expand-file-name "$(base)/ansible-$(version)/lib"))
emacs +=   (setenv "PATH" (concat (expand-file-name "$(base)/ansible-$(version)/bin:") (getenv "PATH"))))

help:
	@echo "sudo mkdir -p $(base); sudo chown $$USER:staff $(base); chmod g+w $(base)"
	@echo
	@$(foreach version,$(versions),echo '$(clone)';)
	@echo
	@$(foreach version,$(versions),echo '$(pull)';)
	@echo
	@$(foreach version,$(versions),echo '$(setup)';)
	@echo
	@$(foreach version,$(versions),echo '$(strip $(emacs))';)

short:
	@$(foreach version,$(versions.short),echo '$(pull)';)
	@$(foreach version,$(versions.short),echo '$(setup)';)

last:
	@$(foreach version,$(version.last),echo '$(clone)';)
	@$(foreach version,$(version.last),echo '$(pull)';)
	@$(foreach version,$(version.last),echo '$(setup)';)

devel := devel
default := $(version.last)
$(foreach stable, $(stables), $(eval $(stable) := stable-$(stable)))
targets := $(stables) devel default
$(targets):
	@$(foreach version,$($@),echo '$(pull)';)
	@$(foreach version,$($@),echo '$(setup)';)

clone pull setup:; @echo '$($@)'

roles:; ansible-galaxy install -i -r requirements.yml

.PHONY: top help clone pull setup roles $(targets)
