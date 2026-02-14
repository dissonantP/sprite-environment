if sprite exec -s $SPRITE_NAME bash -c 'command -v sshd >/dev/null && sprite-env services list 2>/dev/null | grep -q "sshd"' > /dev/null 2>&1; then
  echo "  OpenSSH already installed and sshd service exists, skipping"
  exit 0
fi

sprite exec -s $SPRITE_NAME bash <<'EOF'
if ! command -v sshd > /dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y openssh-server
fi

if ! sprite-env services list 2>/dev/null | grep -q "sshd"; then
  sprite-env services create sshd --cmd /usr/sbin/sshd
fi
EOF
