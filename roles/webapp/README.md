# Webapp Role

This role renders the stack-level files and runs the Inception stack on the remote host.

## Runtime Flow

- `tasks/main.yml` creates the shared deployment directories under `deploy_path`.
- `docker-compose.yml` and `.env` are rendered from Ansible variables and Vault secrets.
- `docker compose up -d --build` starts the stack on the remote host.

## File Responsibilities

- `files/wordpress/tools/wordpress_init.sh` bootstraps WordPress, refreshes the DB config, and keeps the admin credentials aligned with Vault.
- `files/mariadb/tools/mariadb_init.sh` initializes the database on first boot and reapplies the database passwords on later boots.
- `templates/*.j2` are rendered on the remote host so domain-specific values and secrets stay centralized in Ansible.

## Container Behavior

- MariaDB initializes the database on a fresh volume and reapplies credentials on later boots.
- WordPress waits for MariaDB, rewrites its database constants from the rendered environment, and keeps the admin and default user credentials in sync.
- Nginx serves the WordPress site over HTTPS using the configured domain name.

## Service Roles

- `roles/mariadb` prepares the MariaDB build context and data directory.
- `roles/wordpress` prepares the WordPress build context and data directory.
- `roles/nginx` prepares the Nginx build context.
