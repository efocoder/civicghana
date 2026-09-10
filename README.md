# CivicRoute

## Containerized development

The development stack runs Rails and PostgreSQL in containers. You only need
Docker with Compose, or Podman with a Compose provider.

Start the application with Docker:

```sh
docker compose up --build
```

Or with Podman:

```sh
podman compose up --build
```

The first start builds the development image, waits for PostgreSQL, and runs
`bin/rails db:prepare`. Open <http://localhost:3000> once Rails is ready.

Run Rails commands in the web container, for example:

```sh
docker compose run --rm web bin/rails console
docker compose run --rm web bin/rails test
```

Replace `docker compose` with `podman compose` when using Podman.

Stop the stack with `docker compose down`. To also delete the development
database and cached gems, use `docker compose down --volumes`.
