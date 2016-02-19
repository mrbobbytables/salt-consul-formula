get-consul-prereqs:
  pkg.installed:
    - name: unzip

create-consul-user:
  group.present:
    - name: consul
  user.present:
    - name: consul
    - system: true
    - groups:
      - consul
    - require:
      - group: consul

