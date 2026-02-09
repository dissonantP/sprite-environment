if sprite exec -s $SPRITE_NAME bash -c 'gh auth status' > /dev/null 2>&1; then
  echo "  gh CLI already authenticated, skipping"
  exit 0
fi

GH_TOKEN=$(gh auth token)
sprite exec -s $SPRITE_NAME bash -c "echo \"$GH_TOKEN\" | gh auth login --with-token"
