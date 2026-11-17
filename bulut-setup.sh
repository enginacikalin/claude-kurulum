#!/bin/bash
# Claude Code bulut ortamı "Setup script" alanına bu dosyanın İÇERİĞİNİ yapıştırın.
# Her yeni bulut oturumu başlamadan önce çalışır ve kur.sh'yi çalıştırır.
# Bir adım başarısız olsa bile oturumun açılmasını engellemez.

D=""
for p in /home/user/claude-kurulum "$HOME/claude-kurulum"; do [ -f "$p/kur.sh" ] && D="$p" && break; done
if [ -z "$D" ]; then
  git clone -q --depth 1 https://github.com/enginacikalin/claude-kurulum "$HOME/claude-kurulum" 2>/dev/null && D="$HOME/claude-kurulum"
fi
if [ -n "$D" ]; then
  bash "$D/kur.sh" || echo "kur.sh bazı adımlarda başarısız oldu; oturum yine de açılıyor."
else
  echo "claude-kurulum deposu bulunamadı: ortam ayarlarında Repositories altına eklendiğini kontrol edin."
fi
exit 0
