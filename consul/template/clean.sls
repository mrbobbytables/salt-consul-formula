#!py


import os
import re
import yaml


def run():
    config = {}
    bin_dir = '/usr/local/bin'
    bin_path = os.path.join(bin_dir, 'consul-template')
    inuse_list = []
    file_list = []
    rem_list = []

    # ensure binary that is in use is not removed
    if os.path.islink(bin_path):
        inuse_list.append(os.readlink(bin_path))

    # replicating map.jinja
    try:
        defaults_path = os.path.join(os.path.dirname(os.path.split(__file__)[0]), 'defaults.yml')
        with open(defaults_path, 'r') as f:
            defaults = yaml.load(f)
        f.close()

        # use salt's dictupdate to merge recursively
        template_settings = defaults['template'].copy()
        __salt__['slsutil.update'](template_settings, __pillar__['consul']['lookup']['template'])

        # don't remove what's in the pillar, or what's symlinked
        pillar_bin_version = os.path.join(bin_dir, 'consul-' + template_settings['pkg']['version'])
        if pillar_bin_version not in inuse_list:
            inuse_list.append(pillar_bin_version)
    except Exception:
        # Can still proceed with cleaning up binaries
        pass

#--------------------#

    file_list = os.listdir(bin_dir)
    for f in file_list:
        if re.match('^consul-template-\d+\.\d+.\d+', f):
            file_path = os.path.join(bin_dir, f)
            if os.path.isfile(file_path) and file_path not in inuse_list:
                rem_list.append(file_path)


    for rem in rem_list:
        config['clean-consul-template-' + os.path.basename(rem)] = {'file.absent': [{ 'name': rem }]}

    return config
