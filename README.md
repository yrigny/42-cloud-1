# cloud-1 / Inception Deployment on a cloud server

This repository deploys the 42 Inception project to the remote host with Ansible.

## High-level Flow

1. `playbook.yml` runs the `docker` role and then the `webapp` role.
2. `roles/docker` installs Docker and the Compose plugin on the target host.
3. `roles/webapp` copies the build contexts, renders the templates, and starts the stack.
4. `group_vars/all.yml` holds the environment values and Vault-managed secrets used by the rendered files.

## Runtime Layout

- `roles/webapp/files/wordpress/tools/wordpress_init.sh` initializes WordPress and keeps its configuration aligned with the current environment.
- `roles/webapp/files/mariadb/tools/mariadb_init.sh` initializes MariaDB on a fresh volume and reapplies credentials on later boots.
- `roles/webapp/templates/docker-compose.yml.j2` defines the service topology used on the remote host.
- `roles/webapp/templates/nginx/conf/default.conf.j2` renders the HTTPS vhost using the configured domain name.

## Notes

- The project uses Ansible Vault for secrets and renders them into `.env` at deploy time.
- The persistent data directories are mounted under `deploy_path`.