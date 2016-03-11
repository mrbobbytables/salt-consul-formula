======
Consul
======
.. image:: https://travis-ci.org/mrbobbytables/salt-consul-formula.svg?branch=master

Formula for managing Consul and Consul Template.

**REQUIRES SALT VERSION v2015.8.4 OR GREATER**


Tested with the following platforms:

- CentOS 6
- CentOS 7
- Debian Jessie
- Debian Wheezy
- Ubuntu Precice (12.04)
- Ubuntu Trusty (14.04)
- Ubuntu Vivid (15.04)


.. contents::

Pillar Structure
==================


``Agent Pillar``
----------------

- ``consul.lookup.agent.checks`` - Array - An array of hashes of supplied checks. All values are converted to json. See the example below for an example.

- ``consul.lookup.agent.config`` - Hash - All supplied parameters under this key are converted to json and used as the consul agent config. See the Consul_ configuration options for more information.

- ``consul.lookup.agent.config.data_dir`` - string - **Default** - ``/var/lib/consul`` - The path to the Consul data directory.

- ``consul.lookup.agent.config.ui`` - binary - **Default** - ``true`` enabled the consul agent web UI.

- ``consul.lookup.agent.log`` - Binary - **Default:** ``true`` - Enable/disable logging.  Disabled by default on systems where systemd is used (journalctl is used instead).

- ``consul.lookup.agent.log_dir`` - String - **Default:** ``/var/log/consul`` - The path to the directory where the log should be stored.

- ``consul.lookup.agent.pkg.install`` - Binary - **Default:** ``true`` - Install Consul.

- ``consul.lookup.agent.pkg.service`` - Binary - **Default:** ``true`` - Install and configure as a service.

- ``consul.lookup.agent.pkg.version`` - String - **Default:** ``0.6.3`` - Version of consul to install.

- ``consul.lookup.agent.opts`` - Hash - All supplied parameters under this key are passed as command line options to the consul agent. Should be supplied as:
  ::
    consul:
      lookup:
        agent:
          opts:
            option_1
            option_2:
            - paramter
      
See the Consul_ configuration options for more information.

- ``consul.lookup.agent.opts.config-dir`` - String - **Default** - ``/etc/consul/agent.d`` - Path to Consul agent configuration directory.

- ``consul.lookup.agent.scripts`` - Array - An array of hashes containing ``name`` (optional) and ``source``. Scripts supplied this way will be copied over to the scripts directory and made available for use with consul service checks.

- ``consul.lookup.agent.scripts_dir`` - String - **Default:** ``/usr/share/consul/agent/scripts``. The path to the directory where scripts associated with consul checks should reside.

- ``consul.lookup.agent.services`` - Array - An array of hashes of supplied service definitions. All values are converted to json. See the example below for an example.

- ``consul.lookup.agent.ssl.ca.name`` - String - **Optional** - Name of CA certificate stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.agent.ssl.ca.source`` - String - Source location of CA certificate.

- ``consul.lookup.agent.ssl.cert.name`` - String - **Optional** - Name of server or consul certificate stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.agent.ssl.cert.source`` - String - Source location of server or consul certificate.

- ``consul.lookup.agent.ssl.dir`` - String - **Default:** ``/etc/consul/ssl`` - Directory to store ssl certificates.

- ``consul.lookup.agent.ssl.enabled`` - Binary - **Default:** ``true`` - Configure consul with ssl support. If enabled, the source configuration parameters for each ssl option are required.

- ``consul.lookup.agent.ssl.key.name``- String - **Optional** - Name of server or consul priate key stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.agent.ssl.key.source``- String - Source location of server or consul private key.

**Pillar Example**

::

 consul:
  lookup:
    agent:
      log: true
      pkg:
        install: true
        service: true
        version: 0.6.3
      ssl: 
        enabled: true
        dir: /etc/consul/ssl
        ca:
          source: salt://test-data/ssl/ca.cert
        cert:
          source: salt://test-data/ssl/consul.cert
        key:
          source: salt://test-data/ssl/consul.key
      opts:
        server: 
      config:
        bootstrap: true
        bind_addr: 0.0.0.0
        client_addr: 0.0.0.0
        retry_interval: 30s
        ca_file: /etc/consul/ssl/ca.cert
        cert_file: /etc/consul/ssl/consul.cert
        key_file: /etc/consul/ssl/consul.key
        verify_incoming: true
        verify_outgoing: true
        ports:
          http: 9999
      scripts:
        -
          source: salt://test-data/agent/scripts/test1.sh
        -
          name: test2
          source: salt://test-data/agent/scripts/test2.sh
      services:
        -
          id: webui
          name: consul-webui
          tags:
            - master
          address: 127.0.0.1
          port: 8500
          checks:
            -
              http: http://127.0.0.1:9999/ui/
              interval: 30s
              timeout: 10s
      checks:
        -
          id: ssh
          name: ssh local
          tcp: localhost:22
          interval: 30s
          timeout: 10s


-----


``Template Pillar``
-------------------


- ``consul.lookup.template.config`` - Hash - All supplied parameters under this key are converted to json and used as the consul template config. See the Consul-Template_ README for more information.

- ``consul.lookup.template.log`` - Binary - **Default:** ``true`` - Enable/disable logging.  Disabled by default on systems where systemd is used (journalctl is used instead).

- ``consul.lookup.template.log_dir`` - String - **Default:** ``/var/log/consul`` - The path to the directory where the log should be stored.

- ``consul.lookup.template.pkg.install`` - Binary - **Default:** ``false`` - Install Consul Template.

- ``consul.lookup.template.pkg.service`` - Binary - **Default:** ``true`` - Install and configure as a service.

- ``consul.lookup.template.pkg.version`` - String - **Default:** ``0.6.3`` - Version of Consul Template to install.

- ``consul.lookup.template.opts`` - Hash - All supplied parameters under this key are passed as command line options to Consul Template. Should be supplied as:
  ::
    consul:
      lookup:
        template:
          opts:
            option_1:
            option_2:
            - paramter
      
See the Consul-Template_ README for more information.

- ``consul.lookup.template.opts.config`` - String - **Default** - ``/etc/consul/template.d`` - Path to Consul Template configuration directory.

- ``consul.lookup.template.ssl.ca.name`` - String - **Optional** - Name of CA certificate stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.template.ssl.ca.source`` - String - Source location of CA certificate.

- ``consul.lookup.template.ssl.cert.name`` - String - **Optional** - Name of server or consul certificate stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.template.ssl.cert.source`` - String - Source location of server or consul certificate.

- ``consul.lookup.template.ssl.dir`` - String - **Default:** ``/etc/consul/ssl`` - Directory to store ssl certificates.

- ``consul.lookup.template.ssl.enabled`` - Binary - **Default:** ``true`` - Configure consul with ssl support. If enabled, the source configuration parameters for each ssl option are required.

- ``consul.lookup.template.ssl.key.name``- String - **Optional** - Name of server or consul priate key stored in the ssl directory. If not configured, it will default to the name from the supplied source.

- ``consul.lookup.template.ssl.key.source``- String - Source location of server or consul private key.

- ``consul.lookup.template.templates`` - Array - An Array of hashes containg ``name`` (optional), ``source`` and ``config`` (hash) with ``config`` being converted to hcl (current issues with json rendering). Example:

- ``consul.lookup.template.templates_dir`` - String - **Default:** ``/usr/share/consul/template/templates`` - The path to the directory that templates supplied in ``consul.lookup.template.templates`` will be stored.

  ::

    consul:
      lookup:
        template:
          templates:
            - 
              name: test1.ctmplt
              source: salt://test-data/template/templates/test_1.ctmplt
              config:
                destination: /tmp/ct_render_test_1
                command: touch /tmp/ct_cmd_test_1


See the Consul-Template_ README for more information on the available template options.

**Pillar Example**

::

  consul:
    lookup:
      template:
        log: true
        ssl: 
          enabled: true
          dir: /etc/consul/ssl
          ca:
            source: salt://test-data/ssl/ca.cert
          cert:
            source: salt://test-data/ssl/consul.cert
          key:
            source: salt://test-data/ssl/consul.key
        pkg:
          install: true
          service: true
        opts:
          consul:
           - 127.0.0.1:9999
        config:
          log_level: debug
          ssl:
            enabled: false
            verify: false
            ca_cert: /etc/consul/ssl/ca.cert
            cert: /etc/consul/ssl/consul.cert
            key: /etc/consul/ssl/consul.cert
        templates:
          - 
            name: test1.ctmplt
            source: salt://test-data/template/templates/test_1.ctmplt
            config:
              destination: /tmp/ct_render_test_1
              command: touch /tmp/ct_cmd_test_1
          -
           source: salt://test-data/template/templates/test_2.ctmplt
           config:
             destination: /tmp/ct_render_test_2
             command: touch /tmp/ct_cmd_test_2
             perms: "0777" 


-----


States
======

``consul``
----------

By default it will only install the Consul prereqs (``consul.prereqs``) and the Consul Agent (``consul.agent``). This can be overriden in the Consul pillar.


``consul.agent``
----------------
 Installs and configures the Consul Agent by including ``consul.agent.install``, ``consul.agent.config``, and ``consul.agent.service``.


``consul.agent.install``
------------------------

Downloads and installs the Consul Agent. The specified version will be downloaded and placed in ``/usr/local/bin/``. It will be renamed to bo ``consul-<version number>``, and symlinked to ``/usr/local/bin/consul``. If upgrading, previous versions are not removed automatically (see ``consul.agent.clean``). Upgrading it done this way in the event a quick-rollback to a previous version is required.


``consul.agent.config``
-----------------------

Configures the Consul Agent.


``consul.agent.service``
------------------------

Enables the Consul Agent to run as a service.


``consul.agent.clean``
----------------------

Removes older versions of Consul previously downloaded. The version that is currently in use and the version specified in the pillar will **not** be removed.


``consul.agent.remove``
----------------------

Removes the Consul Agent. It will **not** removed shared resources such as the ssl directory.


-----


``consul.template``
----------------

 Installs and configures Consul Template by including ``consul.template.install``, ``consul.template.config``, and ``consul.template.service``.


``consul.template.install``
------------------------

Downloads and installs Consul Template. The specified version will be downloaded and placed in ``/usr/local/bin/``. It will be renamed to bo ``consul-template-<version number>``, and symlinked to ``/usr/local/bin/consul-template``. If upgrading, previous versions are not removed automatically (see ``consul.template.clean``). Upgrading it done this way in the event a quick-rollback to a previous version is required.


``consul.template.config``
-----------------------

Configures Consul Template.


``consul.template.service``
------------------------

Enables Consul Template to run as a service.


``consul.template.clean``
----------------------

Removes older versions of Consul Template previously downloaded. The version that is currently in use and the version specified in the pillar will **not** be removed.

``consul.template.remove``
----------------------

Removes Consul Template. It will **not** removed shared resources such as the ssl directory.



.. _Consul: https://www.consul.io/docs/agent/options.html
.. _Consul-Template: https://github.com/hashicorp/consul-template
