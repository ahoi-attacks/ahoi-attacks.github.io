PWD=$$(pwd)
SCRIPT_DIR=$(shell cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJ_ROOT=$(SCRIPT_DIR)
TOOLS_DIR=$(PROJ_ROOT)/tools

all: dev

.PHONY:
init:
	cd "$(PROJ_ROOT)/hugo" && npm install

.PHONY:
dev:
	cd "$(PROJ_ROOT)/hugo" && npm run dev


.PHONY:
build:
	cd "$(PROJ_ROOT)/hugo" && npm run build
