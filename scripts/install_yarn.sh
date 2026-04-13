if sprite_exec bash -c 'command -v yarn' > /dev/null 2>&1; then
  echo "  Yarn already installed, skipping"
  exit 0
fi

sprite_exec bash -c 'npm install --global yarn'
