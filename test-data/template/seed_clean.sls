fake-template-binary-1:
  file.append:
    - name: /usr/local/bin/consul-template-0.0.1
    - text:
      - I am a fake version of consul


fake-template-binary-2:
  file.append:
    - name: /usr/local/bin/consul-template-0.0.2
    - text:
      - I am a fake version of consul also

