{# sleep a brief bit to allow consul to fully come up #}

sleep-before-attepting-to-insert:
  cmd.run:
    - name: sleep 10

insert-consul-test-kv-1:
  module.run:
    - name: consul.put
    - consul_url: http://127.0.0.1:9999
    - key: test1
    - value: data1

insert-consul-test-kv-2:
  module.run:
    - name: consul.put
    - consul_url: http://127.0.0.1:9999
    - key: test2
    - value: data2

