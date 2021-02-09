### This ansible script is designed for deploying a rust-based freeton node on dedicated or virtual servers.

---
## Compatibility

#### Minimum OS versions:
Ubuntu: 18.04

#### Ansible version
This has been tested on Ansible 2.9.х

## Requirements
This playbook requires root privileges or sudo.
Ansible ([What is Ansible](https://www.ansible.com/resources/videos/quick-start-video)?)

---
## Deployment: quick start
0. [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) to the managed machine
###### Example: install ansible on [Ubuntu](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-ubuntu)
`sudo apt update`\
`sudo apt install ansible sshpass git`

1. Download or clone this repository

`git clone https://github.com/itgoldio/freeton-rustnode-ansible.git`

2. Go to the playbook directory

`cd freeton-rustnode-ansible/`

3. Edit the inventory file

###### Specify the IP addresses in freeton_node and monitoring_server section and connection settings (`ansible_user`, `ansible_ssh_pass` ...) for your environment. If you run  the playbook locally, don't change the default settings.
###### Example:

`vim inventory`

`[freeton_node]`\
`11.22.33.44 ansible_user='root' ansible_ssh_pass='secretpassword'`\
`22.33.44.55 ansible_user='user' ansible_ssh_pass='supersecretpassword' ansible_become=true`\
`[monitoring_server]`\
`33.44.55.66`

###### There is no need to specify more than one monitoring server. All agents will connect only to the first one.

4. Edit the variable files vars/[freeton_node.yml](./vars/freeton_node.yml), vars/[system.yml](./vars/system.yml) and vars/[monitoring.yml](./vars/monitoring.yml)

`vim vars/freeton_node.yml`\
`vim vars/system.yml`\
`vim vars/monitoring.yml`

### Be careful and don't forget to change standard passwords in [monitoring.yml](./vars/monitoring.yml) file.

5. Run playbook:

`ansible-playbook deploy_freeton_node.yml`

##### If you run playbook locally, use -c local parameter

`ansible-playbook deploy_freeton_node.yml -c local`

##### To skip monitoring server installation role, specify '-t basic'

`ansible-playbook deploy_freeton_node.yml -c local -t basic`

---
## Variables
See the vars/[freeton_node.yml](./vars/freeton_node.yml), vars/[system.yml](./vars/system.yml) and vars/[monitoring.yml](./vars/monitoring.yml) files for more details.

---
## Usage
By default, after deploying the freeton node it gets started automatically (change this behavior in vars/[freeton_node.yml](./vars/freeton_node.yml)).
You can control the running status of the freeton node using systemd commands:
`systemctl status freeton`\
`systemctl stop freeton` \
`systemctl start freeton`

Freeton node stores logs in `/opt/freeton/logs` directory (change this by specifying freeton_node_log_dir var in vars/[freeton_node.yml](./vars/freeton_node.yml)).
You can change log rules in file roles/freeton_node_deploy/freeton_node_deploy/[log_cfg.yml.j2](./roles/freeton_node_deploy/templates/log_cfg.yml.j2)

Binary files located in `/opt/freeton/bin`, all other locations stored in vars/[freeton_node.yml](./vars/freeton_node.yml)


Monitoring services will start at the host specified in monitoring_server inventory section.
You can access Grafana the monitoring observability solution with pre-installed dashboards via a web-browser:

`http://<monitoring_server_ip>:3000/`

Also you can access Chronograf - InfluxDB data observation tool - via a web-browser:

`http://<monitoring_server_ip>:8888/`

---
## Extras
When you change global network config, for example, you running rustnet.ton.dev network, and want to change it to fld.ton.dev. You should change freeton_node_global_config_URL variable in vars/[freeton_node.yml](./vars/freeton_node.yml) and run playbook again with tag 'flush':

`ansible-playbook deploy_freeton_node.yml -c local -t flush`

---
## Support
We can help you in telegram chats
- RU: https://t.me/itgoldio_support_ru
- EN: https://t.me/itgoldio_support_en

## Changelog
Here: [changelog.md](./changelog.md)
