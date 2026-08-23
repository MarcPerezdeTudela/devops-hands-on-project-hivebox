# syntax=docker/dockerfile:1

FROM python:3.13.15-slim-bookworm@sha256:00faa2debb87529f9f0764e9491d8ba400a3678976616c3bd7cb193745ac20d1 AS builder

ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

RUN python -m venv --without-pip "$VIRTUAL_ENV"

COPY pyproject.toml README.md ./
COPY src ./src

RUN --mount=type=cache,target=/root/.cache/pip \
    /usr/local/bin/python -m pip --python "$VIRTUAL_ENV" install .

FROM python:3.13.15-slim-bookworm@sha256:00faa2debb87529f9f0764e9491d8ba400a3678976616c3bd7cb193745ac20d1 AS runtime

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN groupadd --gid 10001 hivebox \
    && useradd --uid 10001 --gid hivebox --no-create-home \
        --home-dir /nonexistent --shell /usr/sbin/nologin hivebox

COPY --from=builder /opt/venv /opt/venv

USER 10001:10001

EXPOSE 8000

CMD ["fastapi", "run", "--entrypoint", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
