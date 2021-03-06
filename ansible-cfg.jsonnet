#!/usr/bin/env jsonnet
# to be invoked as `$0 -m $ansible_cfg_dir -S -V repo=$(git config remote.origin.url)`

local ssh = {
  base: {
    pipelining: true,
  },
};

local inventory = {
  base: {
    enable_plugins: 'yaml, ini, host_list',
  },
};

local locals = {
  cached_inventory: {
    path:: '.cache/inventory',
    cached_inventory: self.path,
  },
};

local defaults = {

  local dir(path) = local tmp = std.split(path, '/'); std.join('/', tmp[:std.length(tmp) - 1]),

  base: {
    inventory: 'inventory',
    hosts: 'default',
    retry_files_enabled: false,
    // dirs:: self.inventory,
  },
  python: {
    // intepreter_python: 'auto_silent'
    intepreter_python: '/usr/bin/python'
  },
  vault: {
    vault_password_file: 'vault-pass.py'
  },
  log: {
    log_path: 'log/ansible.log',
    dirs:: dir(self.log_path),
  },
  caching: {
    fact_caching: 'jsonfile',
    fact_caching_connection: '.cache/ansible',
    fact_caching_timeout: 86400,
    dirs:: self.fact_caching_connection,
  },
  cached_inventory: {
    path:: locals.cached_inventory.path,
    inventory: std.join(',', [ $.base.inventory, self.path ]),
    dirs: self.path,
    files: self.dirs + "/dummy",
  },
  retry: {
    retry_files_enabled: true,
    retry_files_save_path: '.retry',
    dirs:: self.retry_files_save_path,
  },
  roles: {
    roles_path: 'roles',
    dirs:: self.roles_path,
  },
  collections: {
    collections_path: 'collections',
    dirs:: self.collections_path,
  },
  filter: {
    filter_plugins: 'plugins/filter',
    action_plugins: 'plugins/action',
    dirs:: [ self.filter_plugins, self.action_plugins ],
  },
  misc: {
    gathering: 'smart',
    merge_multiple_cli_tags: true,
    stdout_callback: 'debug',
    'jinja2_extensions': 'jinja2.ext.do',
    ansible_managed: 'Ansible managed',
  },
};

local collect(v, k, l = []) =
  local clean(l) = std.flattenArrays(std.prune(l));
  if std.isObject(v) then
    local f = std.setDiff(std.set(std.objectFieldsAll(v)),[k]),
          r = clean([ collect(v[i], k, l) for i in f ]);
    if std.objectHasAll(v, k) then
       l + if std.isArray(v[k]) then v[k] else [ v[k] ] + r
    else
       l + r
  else if std.isArray(v) then
    l + clean([ collect(i, k, l) for i in v ]);

local confs = {

  local merge(a) = std.foldl(function(b, k) b + a[k], std.objectFields(a), {}),

  mini: {
    sections: {
      defaults: defaults.base,
      ssh: ssh.base,
      inventory: inventory.base,
    },
  },


  simple: self.mini + { sections +: { defaults +: defaults.log }},
  cached_inventory: self.simple + {sections +: { defaults +: defaults.cached_inventory, locals: locals.cached_inventory }},
  median: self.cached_inventory + { sections +: { defaults +:
      defaults.python + defaults.log + defaults.roles + defaults.collections
    + defaults.caching + defaults.filter + defaults.misc }},
  full: self.median + { sections +: { defaults: merge(defaults) }},
};

local mode = '# -*- Mode: conf; -*-';
local info = '# Generated from ' + std.thisFile + ' on ' + std.extVar('repo');
local headerIni = std.join('\n', [ mode, info, '\n' ]);
local headerYml = std.join('\n', [ '---\n', info, '\n' ]);

{
  [conf + '.cfg']: headerIni + std.manifestIni(confs[conf]) for conf in std.objectFields(confs) } + {

  local p = [ defaults.log.dirs, defaults.collections.dirs ],
  local c = collect(defaults, 'dirs'),
  local f = collect(defaults, 'files'),
  local i = std.uniq(std.sort(std.map(base, c))),
  local base(path) = std.split(path, '/')[0],
  'dirs.yml': headerYml + std.manifestYamlDoc({ dirs: c + p, gitignore: i }),
  'files.yml': headerYml + std.manifestYamlDoc({ files: f }),
  'dirs.mk': info + '\n\ndirs := ' + std.join(' ', p)
}
  
# Local Variables:
# indent-tabs-mode: nil
# End:
