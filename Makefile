# pg_embed/Makefile

PG_CONFIG ?= pg_config
EXTENSION  = pg_embed
CONTROL    = pg_embed.control
SQL        = pg_embed--1.0.sql

# Capture sharedir once, as a Make variable:
SHAREDIR   = $(shell $(PG_CONFIG) --sharedir)

install:
	@echo "Installing $(EXTENSION) into $(SHAREDIR)/extension …"
	# Create extension folder (requires root)
	sudo mkdir -p "$(SHAREDIR)/extension"
	# Copy control and SQL files
	sudo cp "$(CONTROL)" "$(SHAREDIR)/extension/"
	sudo cp "$(SQL)"     "$(SHAREDIR)/extension/"

clean:
	@echo "Nothing to clean."
