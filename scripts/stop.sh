#!/bin/bash

# Script para parar todos os serviços
# Uso: ./scripts/stop.sh

echo "🛑 Parando serviços PetID..."

docker-compose down

echo "✅ Serviços parados!"

