#!/usr/bin/make -f

MAKEFLAGS += -Rr
SHELL := $(shell which bash)

top:; @date

install_dir := /usr/local/bin
install_list := $(patsubst %, ansible-cfg.%, jsonnet mk yml)
$(install_dir)/%: %; install $< $@; $(if $($*),(cd $(@D); $(strip $(foreach _, $($*), ln -sf $* $_;))))
install: $(install_list:%=$(install_dir)/%);

repo != git config remote.origin.url

stone := ansible-cfg/.stone
$(stone): $(install_dir)/ansible-cfg.jsonnet; mkdir -p $(@D); jsonnet -m $(@D) -S -V repo=$(repo) $< && touch $@

confs := mini full simple median nodes_groups
$(confs): $(stone); ln -sf ansible-cfg/$@.cfg ansible.cfg
main: full

.PHONY: top $(confs) main
