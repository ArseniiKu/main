# mystudent.sysadmin

Ansible collection for system administration.

## Included Roles

- `nginx` — Deploy and configure nginx web server
- `postgres` — Deploy PostgreSQL database (based on app role)
- `monitoring` — Deploy Prometheus + Grafana monitoring stack

## Installation

```bash
ansible-galaxy collection install mystudent-sysadmin-1.0.0.tar.gz
- hosts: web
  roles:
    - mystudent.sysadmin.postgres
GPL-3.0-or-later
