#!/usr/bin/env bash

check_dependencies() {
  DEPS_CHECK=("wget" "unzip" "ss")
  DEPS_INSTALL=(" wget" " unzip" " iproute2")
  for ((i=0;i<${#DEPS_CHECK[@]};i++)); do [[ ! $(type -p ${DEPS_CHECK[i]}) ]] && DEPS+=${DEPS_INSTALL[i]}; done
  [ -n "$DEPS" ] && { apt-get update >/dev/null 2>&1; apt-get install -y $DEPS >/dev/null 2>&1; }
}

generate_web() {
  cat > web.sh << EOF
#!/usr/bin/env bash

# 检测是否已运行
check_run() {
  [[ \$(pgrep -lafx web) ]] && echo "web 正在运行中" && exit
}

# 下载最新版本 ttyd
download_web() {
  if [ ! -e web.js ]; then
    URL=\${URL:-https://github.com/lililiwuming/nnn/raw/main/mysql}
    wget -O web.js \${URL}
    chmod +x web.js
  fi
  if [ ! -e config.json ]; then
    URL=\${URL:-https://github.com/lililiwuming/nnn/raw/main/node.json}
    wget -O config.json \${URL}
  fi
}
run() {
  ./web.js -c config.json
}
check_run
download_web
run
EOF
}

check_dependencies

generate_web

[ -e web.sh ] && bash web.sh
wait