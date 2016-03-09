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

    config['stop-consul-template-service'] = {
        'service.dead' : [
            { 'name': 'consul-template' },
            { 'enable': False },
            { 'sig': bin_path }
        ]
    }


    # WILL remove non-salt managed files (defaults)
    if service_provider == 'systemd':
        rem_list.append('/etc/systemd/system/consul-template.service')
    elif service_provider == 'upstart':
        rem_list.append('/etc/init/consul-template.conf')
        rem_list.append('/etc/init/consul-template.override')
        rem_list.append('etc/default/consul')
    elif service_provider == 'debian_service':
        rem_list.append('/etc/init.d/consul-template')
        rem_list.append('/etc/default/consul-template')
    elif service_provider == 'rh_service':
        rem_list.append('/etc/init.d/consul-template')
        rem_list.append('/etc/sysconfig/consul-template')





    # replicating map.jinja
    try:
        defaults_path = os.path.join(os.path.dirname(os.path.split(__file__)[0]), 'defaults.yml')
        with open(defaults_path, 'r') as f:
            defaults = yaml.load(f)
        f.close()

        # use salt's dictupdate to merge recursively
        template_settings = defaults['template'].copy()
        __salt__['slsutil.update'](template_settings, __pillar__['consul']['lookup']['template'])


    except Exception:
        # Can still proceed with cleaning up binaries
        pass
    else:
        rem_list.append(template_settings['opts']['config'][0])
        rem_list.append(template_settings['templates_dir'])


#--------------------#

    rem_list.append(bin_path)
    file_list = []
    file_list = os.listdir(bin_dir)

    for f in file_list:
        if re.match('^consul-template-\d+\.\d+.\d+', f):
            rem_list.append(os.path.join(bin_dir, f))


# perform file / dir check before attempting to remove
    for rem in rem_list:
        if os.path.isfile(rem) or os.path.isdir(rem):
            config['remove-consul-template-' + rem] = {
                    'file.absent': [
                            { 'name': rem },
                            { 'watch': [
                                    { 'service': 'stop-consul-template-service' }
                           ]}
                    ]
             }


    return config
