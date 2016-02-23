#!py

import os
import re
import yaml


def run():
    config = {}

    bin_dir = '/usr/local/bin'
    bin_path = os.path.join(bin_dir, 'consul')
    rem_list = []
    service_provider = __salt__['test.provider']('service').lower()

    config['stop-consul-agent-service'] = {
        'service.dead' : [
            { 'name': 'consul' },
            { 'enable': False },
            { 'sig': bin_path }
        ]
    }


    # WILL remove non-salt managed files (defaults)
    if service_provider == 'systemd':
        rem_list.append('/etc/systemd/system/consul.conf')
    elif service_provider == 'upstart':
        rem_list.append('/etc/init/consul.conf')
        rem_list.append('/etc/init/consul.override')
        rem_list.append('etc/default/consul')
    elif service_provider == 'debian_service':
        rem_list.append('/etc/init.d/consul')
        rem_list.append('/etc/default/consul')
    elif service_provider == 'rh_service':
        rem_list.append('/etc/init.d/consul')
        rem_list.append('/etc/sysconfig/consul')





    # replicating map.jinja
    try:
        defaults_path = os.path.join(os.path.dirname(os.path.split(__file__)[0]), 'defaults.yml')
        with open(defaults_path, 'r') as f:
            defaults = yaml.load(f)
        f.close()

        # use salt's dictupdate to merge recursively
        agent_settings = defaults['agent'].copy()
        __salt__['slsutil.update'](agent_settings, __pillar__['consul']['lookup']['agent'])
        agent_settings.update({ 'data_dir': agent_settings['config']['data_dir']})
        agent_settings.update({ 'ui_dir' : agent_settings['config']['ui_dir'] })

        if 'data-dir' in agent_settings['opts']:
            agent_settings.update({ 'data_dir' : agent_settings.opts['data-dir'][0] })

        if 'ui-dir' in agent_settings['opts']:
            agent_settings.update({ 'ui_dir' : agent_settings.opts['ui-dir'][0] })

    except Exception:
        # Can still proceed with cleaning up binaries
        pass
    else:

        rem_list.append(agent_settings['opts']['config-dir'][0])
        rem_list.append(agent_settings['data_dir'])
        rem_list.append(agent_settings['script_dir'])
        rem_list.append(agent_settings['ui_dir'])

        ui_prefix = os.path.basename(agent_settings['ui_dir'])
        ui_dir = os.path.dirname(agent_settings['ui_dir'])
        dir_list = []
        dir_list = os.listdir(ui_dir)

        for d in dir_list:
            if re.match('^' + ui_prefix + '-\d+\.\d+\.\d+', d):
                rem_list.append(os.path.join(ui_dir, d))

#--------------------#

    rem_list.append(bin_path)
    file_list = []
    file_list = os.listdir(bin_dir)

    for f in file_list:
        if re.match('^consul-\d+\.\d+.\d+', f):
            rem_list.append(os.path.join(bin_dir, f))


# perform file / dir check before attempting to remove
    for rem in rem_list:
        if os.path.isfile(rem) or os.path.isdir(rem):
            config['remove-consul-agent-' + rem] = {
                    'file.absent': [
                            { 'name': rem },
                            { 'watch': [
                                    { 'service': 'stop-consul-agent-service' }
                           ]}
                    ]
             }


    return config
