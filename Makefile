SHELL := /bin/bash

SIMULATOR_NAME ?= iPhone 17
CONFIGURATION ?= Debug
DERIVED_DATA_PATH ?= $(CURDIR)/build
BUNDLE_ID ?= com.example.PocSandbox

export SIMULATOR_NAME CONFIGURATION DERIVED_DATA_PATH BUNDLE_ID

.DEFAULT_GOAL := help

.PHONY: help generate build debug release run open clean distclean

help:
	@echo "Uso: make <alvo>"
	@echo ""
	@echo "  generate   Gera o .xcodeproj e instala os pods"
	@echo "  build      Compila o workspace ($(CONFIGURATION))"
	@echo "  debug      Compila em Debug"
	@echo "  release    Compila em Release"
	@echo "  run        Compila, instala e executa no simulador"
	@echo "  open       Abre o workspace no Xcode"
	@echo "  clean      Remove o diretório de build local"
	@echo "  distclean  Remove build, Pods e arquivos gerados"
	@echo ""
	@echo "Variáveis: SIMULATOR_NAME=$(SIMULATOR_NAME) CONFIGURATION=$(CONFIGURATION)"

generate:
	./scripts/generate.sh

build:
	./scripts/build.sh

debug:
	$(MAKE) build CONFIGURATION=Debug

release:
	$(MAKE) build CONFIGURATION=Release

run:
	./scripts/run.sh

open:
	open PocSandbox.xcworkspace

clean:
	rm -rf "$(DERIVED_DATA_PATH)"

distclean:
	$(MAKE) clean
	rm -rf PocSandbox.xcodeproj PocSandbox.xcworkspace Pods Podfile.lock
	@echo "Arquivos gerados removidos. Rode 'make generate' para recriar."
