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

