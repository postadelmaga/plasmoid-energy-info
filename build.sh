#!/bin/bash

# Creazione del file .plasmoid
echo "Creazione di energy-info.plasmoid..."

zip -r energy-info.plasmoid energy-info/ \
  -x "energy-info/.git/*"

# Verifica che il file sia stato creato
if [ -f "energy-info.plasmoid" ]; then
    echo "✓ File energy-info.plasmoid creato con successo!"
else
    echo "✗ Errore nella creazione del file .plasmoid"
    exit 1
fi