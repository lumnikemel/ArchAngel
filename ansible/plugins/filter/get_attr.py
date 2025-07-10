#!/usr/bin/env python
"""
Ansible filter plugin to convert key/val based array
into a key:val dictionary.
Filter supports custom names for key/val.

This is a workaround for the deliberate design decisiong to 
disallow jinja expansion in dictionary keys. See here:
https://github.com/ansible/ansible/issues/17324

Author: DevOps <devops@flaconi.de>
Version: v0.1
Date: 2018-05-24
Webpage: https://github.com/cytopia/ansible-filter-get_attr

Usage:
var: "{{ an.array | default({}) | get_attr('key', 'val') }}"
"""

class FilterModule(object):
  def filters(self):
    return {
      'get_attr': filter_list
    }
def filter_list(array, key, value):
  a = {}
  for i in array:
    a[i[key]] = i[value]
  return a