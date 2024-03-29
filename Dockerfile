ARG ELIXIR_VERSION
ARG OTP_VERSION

FROM docker.io/library/elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION} AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy sources
RUN mkdir /build
COPY . /build/

# Build the release
WORKDIR /build
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=prod mix release

FROM docker.io/library/elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim

ARG SERVICE_NAME

# Set env
ENV CHARSET=UTF-8
ENV LANG=C.UTF-8

# Expose SERVICE_NAME as env so CMD expands properly on start
ENV SERVICE_NAME=${SERVICE_NAME}

# Set runtime
WORKDIR /opt/${SERVICE_NAME}

COPY --from=builder /build/_build/prod/rel/${SERVICE_NAME} /opt/${SERVICE_NAME}

RUN echo "#!/bin/sh" >> /entrypoint.sh && \
    echo "exec /opt/${SERVICE_NAME}/bin/${SERVICE_NAME} foreground" >> /entrypoint.sh && \
    chmod +x /entrypoint.sh
ENTRYPOINT []
CMD ["/entrypoint.sh"]

EXPOSE 8080
