fake-agent-binary-1:
  file.append:
    - name: /usr/local/bin/consul-0.0.1
    - text:
      - I am a fake version of consul


fake-agent-binary-2:
  file.append:
    - name: /usr/local/bin/consul-0.0.2
    - text:
      - I am a fake version of consul also

