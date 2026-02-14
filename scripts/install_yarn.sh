if sprite exec -s $SPRITE_NAME bash -c 'command -v yarn' > /dev/null 2>&1; then
  echo "  Yarn already installed, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash -c 'npm install --global yarn'
