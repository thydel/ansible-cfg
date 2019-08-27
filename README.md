An helper to avoid keeping `ansible.cfg` in playbook repos.

From this repo

- `make install` will install `ansible-cfg.mk`, `ansible-cfg.jsonnet` and `ansible-cfg.yml` in `/usr/local/bin`

From any pristine ansible playbook repo

- `ansible-cfg.mk $config` will invoke `ansible-cfg.jsonnet` to create
  various ansible configs in `ansible-cfg` and link `ansible.cfg` to `$config` (default to `full`)
  
- `ansible-cfg.yml -e dir=$(pwd)` will create local dirs needed by
  ansible config and populate `.gitignore`
