sprite exec -s $SPRITE_NAME bash -c 'cat > /home/sprite/CHEATSHEET.md <<EOF
# Sprite Cheatsheet

## Docker Compose

Run a one-off command:

    sudo docker compose run --rm <service> <cmd>

Example:

    sudo docker compose run --rm scraper bin/run_scraper --sources=ElisMileHighClub

The service name comes from docker-compose.yml (not the container name).
EOF'
