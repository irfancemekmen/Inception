*This project has been created as part of the 42 curriculum by iekmen.*

# Inception

## Description

Inception is a system-administration project built around Docker. The goal is to set
up a small, self-hosted web infrastructure — entirely from custom-built images —
where several isolated services run in dedicated containers and communicate over a
private Docker network.

The stack is composed of three mandatory services, each in its own container:

- **NGINX** – the only entry point, exposed on port `443` with TLSv1.2 / TLSv1.3 only.
- **WordPress + php-fpm** – the CMS / application layer (no web server inside the container).
- **MariaDB** – the relational database that stores all WordPress data.

Two Docker named volumes persist data on the host under `/home/iekmen/data`: one for
the database, one for the WordPress site files. A dedicated bridge network
(`inception_network`) links the containers; only NGINX is reachable from outside.

All images are built locally from `debian:bookworm` (the penultimate stable Debian
release). Pulling ready-made service images (WordPress, NGINX, MariaDB, …) is
forbidden by the subject; Alpine/Debian base images are the only exception.

## Instructions

### Prerequisites

- A Linux host (ideally a Virtual Machine) with `docker` and the `docker compose` plugin.
- `make`.
- An entry in `/etc/hosts` so the domain resolves locally:

  ```
  127.0.0.1   iekmen.42.fr
  ```

### Configuration

Non-secret configuration lives in `srcs/.env`; **passwords are kept out of `.env`**
and provided through Docker secrets. Both `srcs/.env` and `secrets/` are git-ignored
and must **never** be committed.

`srcs/.env` — only non-sensitive values:

```env
DOMAIN_NAME=iekmen.42.fr

MYSQL_DATABASE=inception_db
MYSQL_USER=inception_user

WP_ADMIN_USER=<admin-name-without-"admin"-or-"administrator">
WP_ADMIN_EMAIL=<email>
WP_NORMAL_USER=<author-name>
WP_NORMAL_EMAIL=<email>
```

`secrets/` at the repository root — one password per file, no trailing newline:

```
secrets/db_root_password.txt     # MariaDB root password
secrets/db_password.txt          # MariaDB user (MYSQL_USER) password
secrets/wp_admin_password.txt    # WordPress admin password
secrets/wp_user_password.txt     # WordPress second user password
```

`docker-compose.yml` mounts these into the `mariadb` and `wordpress` containers at
`/run/secrets/<name>`; the entrypoint scripts read the passwords from there.

### Build and run

| Command | Effect |
| --- | --- |
| `make` / `make all` | Creates the host data directories and builds + starts all containers in the background. |
| `make down` | Stops and removes the containers (data kept). |
| `make clean` | `down` + removes images and volumes. |
| `make fclean` | `clean` + deletes host data in `/home/iekmen/data` and prunes unused Docker objects. |
| `make re` | `fclean` then `all`. |

Then open <https://iekmen.42.fr> and accept the self-signed certificate. The admin
panel is at <https://iekmen.42.fr/wp-admin>.

## Resources

Documentation and references used:

- **Docker docs** – Dockerfile best practices, `docker compose` file reference, named
  volumes, user-defined bridge networks.
- **NGINX docs** – `ssl_protocols`, FastCGI (`fastcgi_pass`), `server` blocks.
- **MariaDB Knowledge Base** – first-run data-directory initialisation, user / `GRANT`
  management, `mysqld_safe`.
- **WordPress + WP-CLI handbook** – `wp core download` / `config create` / `core install`,
  `wp user create`.
- **Debian package archive** – checking which PHP version ships with each Debian
  release (bullseye → PHP 7.4, bookworm → PHP 8.2).
- Articles on **PID 1 in containers** and why `tail -f`, `sleep infinity`, `while true`
  are anti-patterns for keeping a container alive.

### Use of AI

AI (Claude) was used as an assistant, not as a code generator, for:

- **Review** – auditing the repository against the subject and listing rule
  violations (a git-tracked `.env`, a PHP version mismatch between the base image and
  the installed packages, missing README sections, an empty `USER_DOC.md`).
- **Explanations** – clarifying trade-offs (named volumes vs bind mounts, secrets vs
  environment variables, PID 1 and entrypoint design).
- **Refactors** – moving every password out of `.env` into Docker secrets read from
  `/run/secrets/` by the entrypoint scripts.
- **Documentation** – drafting and structuring the Markdown files (this README and
  `USER_DOC.md`).

All Dockerfiles, configuration files and shell scripts were written and are understood
by the author; AI output was reviewed and adapted, never copy-pasted blindly.

## Project description

### Docker and the project sources

Each service has its own directory under `srcs/requirements/<service>/` containing:

- a `Dockerfile` built from `debian:bookworm`;
- a `conf/` folder with the service configuration;
- a `tools/` folder with the entrypoint script (for MariaDB and WordPress).

`srcs/docker-compose.yml` wires everything together: builds, container names,
`restart: always`, the `inception_network` bridge, the two named volumes, the Docker
secrets, and the single published port (`443`, NGINX only). The root `Makefile`
merely orchestrates `docker compose`.

Main design choices:

- **One process per container.** Each entrypoint ends with `exec <daemon>` so the
  service becomes PID 1 (correct signal handling, no `tail -f` / `while true` hacks).
- **NGINX as the sole gateway.** Only port `443`, TLSv1.2 / TLSv1.3, with a
  self-signed certificate generated at build time.
- **WordPress waits for MariaDB** in its init script before running WP-CLI, instead
  of relying on `depends_on` alone (which does not wait for readiness).
- **Passwords via Docker secrets**, non-secret settings via a git-ignored `.env`; no
  password is written in any Dockerfile or in `.env`.

### Virtual Machines vs Docker

A virtual machine virtualises hardware: each guest ships a full kernel and OS,
costing gigabytes of RAM and minutes to boot. A container virtualises the operating
system: it shares the host kernel and isolates processes with **namespaces** (PID,
network, mount, …) and limits resources with **cgroups** (CPU, RAM). Containers are
megabytes in size and start in seconds, which is why running one service per
container is practical here. The project as a whole still runs inside a VM, as the
subject requires.

### Secrets vs Environment Variables

Environment variables (`.env` + `env_file`) are simple but leak easily: they appear
in `docker inspect`, `/proc/<pid>/environ`, child processes and logs, and the file is
trivially committed by mistake. Docker **secrets** are mounted as files under
`/run/secrets/`, are not exposed in the environment, and are only visible to services
that explicitly declare them. This project uses the `.env` file (mandatory per the
subject) **only for non-sensitive values** — the domain, the database name, usernames
and e-mails — and keeps every password in a Docker secret read from `/run/secrets/`
by the entrypoint scripts. Both `.env` and `secrets/` are git-ignored.

### Docker Network vs Host Network

With `network_mode: host` a container shares the host network stack directly: no
isolation, potential port conflicts, and every internal service reachable from
outside. A user-defined bridge network (`inception_network`) gives each container its
own interface and an internal DNS, so containers reach each other by service name
(e.g. `mariadb:3306`, `wordpress:9000`) and nothing is exposed unless a port is
explicitly published. Only NGINX publishes `443`; MariaDB (`3306`) and php-fpm
(`9000`) stay internal. `network_mode: host`, `--link` and `links:` are forbidden by
the subject.

### Docker Volumes vs Bind Mounts

A bind mount maps an arbitrary host path into a container; it is host-path dependent
and not managed by Docker. A **named volume** is managed by Docker and has its own
lifecycle, and is the storage type required here. The subject also requires the data
to live under `/home/iekmen/data`, so both named volumes are declared with the
`local` driver and `driver_opts` (`type: none`, `o: bind`,
`device: /home/iekmen/data/...`): Docker still manages them as named volumes while the
bytes land in the required host directory. Plain bind mounts declared directly in a
service's `volumes:` list are not allowed for these two persistent storages.
