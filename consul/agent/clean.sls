#!py


import os
import re
import yaml


def run():
    config = {}
    bin_dir = '/usr/local/bin'
    bin_path = os.path.join(bin_dir, 'consul')
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
        agent_settings = defaults['agent'].copy()
        __salt__['slsutil.update'](agent_settings, __pillar__['consul']['lookup']['agent'])
        agent_settings.update({ 'ui_dir' : agent_settings['config']['ui_dir'] })

        if 'ui-dir' in agent_settings['opts']:
            agent_settings.update({ 'ui_dir' : agent_settings.opts['ui-dir'][0] })

        # don't remove what's in the pillar, or what's symlinked
        pillar_bin_version = os.path.join(bin_dir, 'consul-' + agent_settings['pkg']['version'])
        if pillar_bin_version not in inuse_list:
            inuse_list.append(pillar_bin_version)
    except Exception:
        # Can still proceed with cleaning up binaries
        pass
    else:
        # We can proceed with UI clean up
        # ensure in use UI dir is not removed
        ui_prefix = os.path.basename(agent_settings['ui_dir'])
        ui_dir = os.path.dirname(agent_settings['ui_dir'])
        pillar_ui_version = os.path.join(ui_dir, ui_prefix + '-' + agent_settings['pkg']['version'])
        dir_list = []

        if os.path.islink(agent_settings['ui_dir']):
            inuse_list.append(os.readlink(agent_settings['ui_dir']))

        if pillar_ui_version not in inuse_list:
            inuse_list.append(pillar_ui_version)

        dir_list = os.listdir(ui_dir)
        for d in dir_list:
            if re.match('^' + ui_prefix + '-\d+\.\d+\.\d+', d):
                dir_path = os.path.join(ui_dir, d)
                if os.path.isdir(dir_path) and dir_path not in inuse_list:
                    rem_list.append(dir_path)

#--------------------#

    file_list = os.listdir(bin_dir)
    for f in file_list:
        if re.match('^consul-\d+\.\d+.\d+', f):
            file_path = os.path.join(bin_dir, f)
            if os.path.isfile(file_path) and file_path not in inuse_list:
                rem_list.append(file_path)


    for rem in rem_list:
        config['clean-consul-agent-' + os.path.basename(rem)] = {'file.absent': [{ 'name': rem }]}

    return config
