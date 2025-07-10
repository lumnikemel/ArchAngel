#!/usr/bin/python -tt
# -*- coding: utf-8 -*-

# Copyright: (c) 2012, Afterburn <http://github.com/afterburn>
# Copyright: (c) 2013, Aaron Bull Schaefer <aaron@elasticdog.com>
# Copyright: (c) 2015, Indrajit Raychaudhuri <irc+code@indrajit.com>
# Copyright: (c) 2017, Ross Williams <me@rosswilliams.id.au>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = '''
---
module: pacman
short_description: Manage packages with I(pacman)
description:
    - Manage packages with the I(pacman) package manager, which is used by
      Arch Linux and its variants.
version_added: "1.0"
author:
    - Ross Williams (@gunzy83)
    - Indrajit Raychaudhuri (@indrajitr)
    - Aaron Bull Schaefer (@elasticdog) <aaron@elasticdog.com>
    - Afterburn
options:
    name:
        description:
            - Name of the package to install, upgrade, or remove.
        aliases: [ package, pkg ]

    state:
        description:
            - Desired state of the package.
        default: present
        choices: [ absent, latest, present ]

    recurse:
        description:
            - When removing a package, also remove its dependencies, provided
              that they are not required by other packages and were not
              explicitly installed by a user.
        type: bool
        default: no
        version_added: "1.3"

    force:
        description:
            - When removing package - force remove package, without any
              checks. When update_cache - force redownload repo
              databases.
        type: bool
        default: no
        version_added: "2.0"

    update_cache:
        description:
            - Whether or not to refresh the master package lists. This can be
              run as part of a package installation or as a separate step.
        type: bool
        default: no
        aliases: [ update-cache ]

    upgrade:
        description:
            - Whether or not to upgrade whole system.
        type: bool
        default: no
        version_added: "2.0"

    as_deps:
        description:
            - Whether or not to install as a dependency of another package.
        type: bool
        default: no
        version_added: "2.4"
    root:
        description:
            - Specify an alternative install root (default is /).
        default: "/"
        version_added: "2.8"
'''

RETURN = '''
packages:
    description: a list of packages that have been changed
    returned: when upgrade is set to yes
    type: list
    sample: [ package, other-package ]
'''

EXAMPLES = '''
- name: Install package foo
  pacman:
    name: foo
    state: present

- name: Upgrade package foo
  pacman:
    name: foo
    state: latest
    update_cache: yes

- name: Remove packages foo and bar
  pacman:
    name: foo,bar
    state: absent

- name: Recursively remove package baz
  pacman:
    name: baz
    state: absent
    recurse: yes

- name: Run the equivalent of "pacman -Sy" as a separate step
  pacman:
    update_cache: yes

- name: Run the equivalent of "pacman -Su" as a separate step
  pacman:
    upgrade: yes

- name: Run the equivalent of "pacman -Syu" as a separate step
  pacman:
    update_cache: yes
    upgrade: yes

- name: Run the equivalent of "pacman -Rdd", force remove package baz
  pacman:
    name: baz
    state: absent
    force: yes

# Install package foo as a dependency for another package
- pacman:
    name: foo
    state: present
    as_deps: yes
'''

import re

from ansible.module_utils.basic import AnsibleModule


class PacmanPackage:

    def __init__(self, pkg):
        self.install_name = pkg
        if re.match(".*\.pkg\.tar(\.(gz|bz2|xz|lrz|lzo|Z))?$", pkg):
            self.package_name = re.sub('-[0-9].*$', '', pkgs[i].split('/')[-1])
        else:
            self.package_name = pkg
        self.installed = False
        self.latest = False
        self.as_deps = False
        self.remote_unavailable = False

    def query_package(self, module, pacman_path):
        lcmd = "%s -Qi %s --root %s" % (pacman_path, self.package_name, module.params['root'])
        lrc, lstdout, lstderr = module.run_command(lcmd, check_rc=False)
        if lrc != 0:
            # package is not installed locally
            return
        self.installed = True
        # get the version installed locally (if any)
        lversion = get_version(lstdout)
        # get the install reason
        install_reason = get_install_reason(lstdout)
        self.as_deps = 'dependency' in install_reason

        rcmd = "%s -Si %s --root %s" % (pacman_path, self.package_name, module.params['root'])
        rrc, rstdout, rstderr = module.run_command(rcmd, check_rc=False)
        # get the version in the repository
        rversion = get_version(rstdout)

        if rrc == 0:
            self.latest = lversion == rversion
        else:
            self.latest = True
            self.remote_unavailable = True

    def get_package_name(self):
        return self.package_name

    def get_install_name(self):
        return self.install_name

    def is_file_install(self):
        return self.package_name != self.install_name

    def is_installed(self):
        return self.installed

    def is_latest(self):
        return self.latest

    def installed_as_deps(self):
        return self.as_deps

    def is_remote_unavailable(self):
        return self.remote_unavailable


def get_version(pacman_output):
    """Take pacman -Qi or pacman -Si output and get the Version"""
    lines = pacman_output.split('\n')
    for line in lines:
        if 'Version' in line:
            return line.split(':')[1].strip()
    return None


def get_install_reason(pacman_output):
    """Take pacman -Qi and get the Install Reason"""
    lines = pacman_output.split('\n')
    for line in lines:
        if 'Install Reason' in line:
            return line.split(':')[1].strip()
    return None


def update_package_db(module, pacman_path):
    if module.params["force"]:
        args = "Syy"
    else:
        args = "Sy"

    cmd = "%s -%s --root %s" % (pacman_path, args, module.params["root"])
    rc, stdout, stderr = module.run_command(cmd, check_rc=False)

    if rc == 0:
        return True
    else:
        module.fail_json(msg="could not update package db")


def upgrade(module, pacman_path):
    cmdupgrade = "%s -Suq --noconfirm --root %s" % (pacman_path, module.params["root"])
    cmdneedrefresh = "%s -Qu --root %s" % (pacman_path, module.params["root"])
    rc, stdout, stderr = module.run_command(cmdneedrefresh, check_rc=False)
    data = stdout.split('\n')
    data.remove('')
    packages = []
    diff = {
        'before': '',
        'after': '',
    }

    if rc == 0:
        regex = re.compile('([\w-]+) ((?:\S+)-(?:\S+)) -> ((?:\S+)-(?:\S+))')
        for p in data:
            m = regex.search(p)
            packages.append(m.group(1))
            if module._diff:
                diff['before'] += "%s-%s\n" % (m.group(1), m.group(2))
                diff['after'] += "%s-%s\n" % (m.group(1), m.group(3))
        if module.check_mode:
            module.exit_json(changed=True, msg="%s package(s) would be upgraded" % (len(data)), packages=packages, diff=diff)
        rc, stdout, stderr = module.run_command(cmdupgrade, check_rc=False)
        if rc == 0:
            module.exit_json(changed=True, msg='System upgraded', packages=packages, diff=diff)
        else:
            module.fail_json(msg="Could not upgrade")
    else:
        module.exit_json(changed=False, msg='Nothing to upgrade', packages=packages)


def get_packages_from_output(stdout, install=True):
    index = 3 if install else 2
    if "Net Change" in stdout.split('\n')[index]:
        # handle the case where VerbosePkgLists = true
        data = stdout.split('\n')[index+2:]
        data = data[:data.index('')]
        for i, item in enumerate(data):
            data[i] = "%s-%s" % item.split()[0], item.split()[1]
    else:
        data = stdout.split('\n')[index].split(' ')[2:]
        data = [ i for i in data if i != '' ]
    return data


def remove_packages(module, pacman_path, packages):
    data = []
    diff = {
        'before': '',
        'after': '',
    }

    if module.params["recurse"] or module.params["force"]:
        if module.params["recurse"]:
            args = "Rs"
        if module.params["force"]:
            args = "Rdd"
        if module.params["recurse"] and module.params["force"]:
            args = "Rdds"
    else:
        args = "R"

    remove_c = 0
    # Using a for loop in case of error, we can report the package that failed
    for package in packages:
        # Query the package first, to see if we even need to remove
        package.query_package(module, pacman_path)
        if not package.is_installed():
            continue

        cmd = "%s -%s %s --noconfirm --noprogressbar --root %s" % (pacman_path, args, package.get_package_name(), module.params["root"])
        rc, stdout, stderr = module.run_command(cmd, check_rc=False)

        if rc != 0:
            module.fail_json(msg="failed to remove %s" % (package))

        if module._diff:
            data = get_packages_from_output(stdout, True)
            for pkg in data:
                diff['before'] += "%s\n" % pkg

        remove_c += 1

    if remove_c > 0:
        module.exit_json(changed=True, msg="removed %s package(s)" % remove_c, diff=diff)

    module.exit_json(changed=False, msg="package(s) already absent")


def install_packages(module, pacman_path, packages, state, as_deps):
    install_c = 0
    update_reason_c = 0
    package_err = []
    message = ""
    data = []
    diff = {
        'before': '',
        'after': ''
    }

    to_install_repos = []
    to_install_files = []
    update_install_reason = []
    for package in packages:
        package.query_package(module, pacman_path)
        if package.is_remote_unavailable() and state == 'latest':
            package_err.append(package)

        if package.installed_as_deps() != as_deps:
            update_install_reason.append(package)

        if package.is_installed() and (state == 'present' or (state == 'latest' and package.is_latest())):
            continue

        if package.is_file_install():
            to_install_files.append(package)
        else:
            to_install_repos.append(package)

    if to_install_repos:
        package_string = " ".join([x.get_install_name() for x in to_install_repos])
        cmd = "%s -S %s --noconfirm --noprogressbar --needed --root %s" % (pacman_path, package_string, module.params["root"])
        rc, stdout, stderr = module.run_command(cmd, check_rc=False)

        if rc != 0:
            module.fail_json(msg="failed to install %s: %s" % (package_string, stderr))

        if module._diff:
            data = get_packages_from_output(stdout, True)
            for pkg in data:
                diff['after'] += "%s\n" % pkg

        install_c += len(to_install_repos)

    if to_install_files:
        package_string = " ".join([x.get_install_name() for x in to_install_files])
        cmd = "%s -U %s --noconfirm --noprogressbar --needed --root %s" % (pacman_path, package_string, module.params["root"])
        rc, stdout, stderr = module.run_command(cmd, check_rc=False)

        if rc != 0:
            module.fail_json(msg="failed to install %s: %s" % (package_string, stderr))

        if module._diff:
            data = get_packages_from_output(stdout, True)
            for pkg in data:
                diff['after'] += "%s\n" % pkg

        install_c += len(to_install_files)

    if update_install_reason:
        operation = "--asdeps" if as_deps else "--asexplicit"
        package_string = " ".join([x.get_package_name() for x in update_install_reason])
        cmd = "%s -D %s %s --root %s" % (pacman_path, package_string, operation, module.params['root'])
        rc, stdout, stderr = module.run_command(cmd, check_rc=False)

        if rc != 0:
            module.fail_json(msg="failed to update install reason for %s: %s" % (package_string, stderr))

        if module._diff:
            data = stdout.split('\n')
            for item in data:
                diff['after'] += "%s\n" % item.split(':')[0]

        # don't increment update reason count if being installed or updated as well
        update_reason_c += len(list(set(update_install_reason)-set(to_install_repos)-set(to_install_files)))

    if update_reason_c > 0:
        message = "Updated the install reason for %s package(s). %s" % (update_reason_c, message)

    if state == 'latest' and len(package_err) > 0:
        message = "But could not ensure 'latest' state for %s package(s) as remote version could not be fetched. %s" % (package_err, message)

    if install_c > 0 or update_reason_c > 0:
        module.exit_json(changed=True, msg="installed %s package(s). %s" % (install_c, message), diff=diff)

    module.exit_json(changed=False, msg="package(s) already installed. %s" % (message), diff=diff)

def check_packages(module, pacman_path, packages, state, as_deps):
    would_be_changed = []
    diff = {
        'before': '',
        'after': '',
        'before_header': '',
        'after_header': '',
    }

    for package in packages:
        package.query_package(module, pacman_path)
        if ((state in ["present", "latest"] and not package.is_installed()) or
                (state == "absent" and package.is_installed()) or
                (state == "latest" and not package.is_latest())):
            would_be_changed.append(package)
            continue

    if would_be_changed:
        if state == "absent":
            state = "removed"

        if module._diff and (state == 'removed'):
            diff['before_header'] = 'removed'
            diff['before'] = '\n'.join(would_be_changed) + '\n'
        elif module._diff and ((state == 'present') or (state == 'latest')):
            diff['after_header'] = 'installed'
            diff['after'] = '\n'.join(would_be_changed) + '\n'

        module.exit_json(changed=True, msg="%s package(s) would be %s" % (
            len(would_be_changed), state), diff=diff)
    else:
        module.exit_json(changed=False, msg="package(s) already %s" % state, diff=diff)


def expand_package_groups(module, pacman_path, pkgs):
    expanded = []

    for pkg in pkgs:
        if pkg:  # avoid empty strings
            cmd = "%s -Sgq %s --root %s" % (pacman_path, pkg, module.params["root"])
            rc, stdout, stderr = module.run_command(cmd, check_rc=False)

            if rc == 0:
                # A group was found matching the name, so expand it
                for name in stdout.split('\n'):
                    name = name.strip()
                    if name:
                        expanded.append(name)
            else:
                expanded.append(pkg)

    return expanded


def main():
    module = AnsibleModule(
            argument_spec=dict(
                name=dict(type='list', aliases=['package', 'pkg']),
                state=dict(type='str', default='present', choices=['absent', 'installed', 'latest', 'present', 'removed']),
                recurse=dict(type='bool', default=False),
                force=dict(type='bool', default=False),
                upgrade=dict(type='bool', default=False),
                update_cache=dict(type='bool', default=False, aliases=['update-cache']),
                as_deps=dict(type='bool', default=False),
                root=dict(type='str', default='/')
            ),
            required_one_of=[['name', 'update_cache', 'upgrade']],
            supports_check_mode=True,
        )

    pacman_path = module.get_bin_path('pacman', True)

    p = module.params

    # normalize the state parameter
    if p['state'] in ['present', 'installed']:
        p['state'] = 'present'
    elif p['state'] in ['absent', 'removed']:
        p['state'] = 'absent'

    if p["update_cache"] and not module.check_mode:
        update_package_db(module, pacman_path)
        if not (p['name'] or p['upgrade']):
            module.exit_json(changed=True, msg='Updated the package master lists')

    if p['update_cache'] and module.check_mode and not (p['name'] or p['upgrade']):
        module.exit_json(changed=True, msg='Would have updated the package cache')

    if p['upgrade']:
        upgrade(module, pacman_path)

    if p['name']:
        pkgs = expand_package_groups(module, pacman_path, p['name'])

        packages = []
        for pkg in pkgs:
            if not pkg:  # avoid empty strings
                continue
            else:
                packages.append(PacmanPackage(pkg))

        if module.check_mode:
            check_packages(module, pacman_path, packages, p['state'], p['as_deps'])

        if p['state'] in ['present', 'latest']:
            install_packages(module, pacman_path, packages, p['state'], p['as_deps'])
        elif p['state'] == 'absent':
            remove_packages(module, pacman_path, packages)


if __name__ == "__main__":
    main()