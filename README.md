# Repmgr extension for PostgreSQL container

[Repmgr](https://repmgr.org/) extension for managing replication and failover in Openshift. Scripts serve to extend PostgreSQL container image using [source-to-image](https://github.com/openshift/source-to-image). Follow [the instructions for image extending](https://github.com/sclorg/postgresql-container/tree/generated/10#extending-image), in the [postgresql-container](https://github.com/sclorg/postgresql-container) project.

## Getting started

Add extension scripts to the existing image:

    $ s2i build --context-dir repmgr-fedora-extension/ https://github.com/mcyprian/postgresql-container-repmgr.git mcyprian/postgresql-10-fedora29-base mcyprian/postgresql-10-fedora29-repmgr:1.0
