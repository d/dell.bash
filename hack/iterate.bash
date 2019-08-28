#!/bin/bash

set -x -e

_main() {
	docker-compose up --build
	docker-compose ps
}

_main "$@"
