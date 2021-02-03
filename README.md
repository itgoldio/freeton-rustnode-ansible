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

`cd freeton-rust-node-ansible/`

3. Edit the inventory file

###### Specify the IP addresses in freeton_node section and connection settings (`ansible_user`, `ansible_ssh_pass` ...) for your environment. If you run  the playbook locally, don't change the default settings.
###### Example:
`[freeton_node]`\
`11.22.33.44 ansible_user='root' ansible_ssh_pass='secretpassword'`\
`22.33.44.55 ansible_user='user' ansible_ssh_pass='supersecretpassword' ansible_become=true`

`vim inventory`

4. Edit the variable files vars/[freeton_node.yml](./vars/freeton_node.yml) and vars/[system.yml](./vars/system.yml)

`vim vars/freeton_node.yml`\
`vim vars/system.yml`

5. Run playbook:

`ansible-playbook deploy_freeton_node.yml`

##### If you run playbook locally, use -c local parameter

`ansible-playbook deploy_freeton_node.yml -c local`

---
## Variables
See the vars/[freeton_node.yml](./vars/freeton_node.yml) and vars/[system.yml](./vars/system.yml) files for more details.

---
## Usage
By default, after deploying the freeton node it gets started automatically (change this behavior in vars/[freeton_node.yml](./vars/freeton_node.yml)).
You can control the running status of the freeton node using systemd commands:
`systemctl status freeton`\
`systemctl stop freeton` \
`systemctl start freeton`

Freeton node stores logs in `/var/log/freeton` directory (change this by specifying freeton_node_log_dir var in vars/[freeton_node.yml](./vars/freeton_node.yml)).
You can change log rules in file roles/freeton_node_deploy/freeton_node_deploy/[log_cfg.yml.j2](./roles/freeton_node_deploy/templates/log_cfg.yml.j2)

Binary files located in `/opt/freeton`, all other locations stored in vars/[freeton_node.yml](./vars/freeton_node.yml)

---
## Support
We can help you in telegram chats
RU: https://t.me/itgoldio_support_ru
EN: https://t.me/itgoldio_support_en