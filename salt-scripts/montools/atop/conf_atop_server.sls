
enable_systemctl:
  cmd.run:
    - name: systemctl enable atop.service

start_systemctl:
  cmd.run:
    - name: systemctl restart atop
