#!/bin/bash 
rm -rf /opt/YeeOS1.0_install && mkdir /opt/
salt-call cp.get_dir salt://product/yeeos/1u0/package/YeeOS1.0_install /opt/
