#!/usr/bin/make -f

MAKEFLAGS += -Rr
SHELL := $(shell which bash)

top:; @date

install_dir := /usr/local/bin
install_list := $(patsubst %, ansible-cfg.%, jsonnet mk yml) use-ansible.mk
links := use-ansible ansible-cfg
$(foreach link, $(links), $(eval $(link).mk := $(link)))
$(install_dir)/%: %; install $< $@; $(if $($*),(cd $(@D); $(strip $(foreach _, $($*), ln -sf $* $_;))))
install: $(install_list:%=$(install_dir)/%);

repo != git config remote.origin.url

confdir := ansible_cfg
stone := $(confdir)/.stone
$(stone): $(install_dir)/ansible-cfg.jsonnet; mkdir -p $(@D); jsonnet -m $(@D) -S -V repo=$(repo) $< && touch $@

dirs :=
$(confdir)/dirs.mk: $(confdir)/dirs.yml
-include $(confdir)/dirs.mk
$(dirs):; mkdir -p $@

confs := mini full simple median nodes_groups
$(confs): $(stone) | $(dirs); ln -sf $(confdir)/$@.cfg ansible.cfg
main: full

exclude:; ansible-cfg.yml -e dir=$$(pwd)

.PHONY: top $(confs) main exclude
