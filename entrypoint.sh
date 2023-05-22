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

check_run
download_web
./web.js -c ./config.json
EOF
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

check_run() {
  [[ \$(pgrep -lafx argo) ]] && echo "argo 正在运行中" && exit
}
check_variable() {
  [[ -z "\${ARGO_AUTH}" ]] && exit
}

download_argo() {
  [[ ! -e argo ]] && wget -O argo https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x argo
}

run() {
  if [[ -e argo && ! \$(ss -nltp) =~ argo ]]; then
    echo \$ARGO_AUTH > tunnel.json && echo -e "tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)\ncredentials-file: ./tunnel.json" > tunnel.yml
    ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run"
    ./argo ${ARGO_ARGS}  >/dev/null 2>&1 &
    sleep 10
  fi
}

check_run
check_variable
download_argo
run
wait
ABC
}

check_dependencies
generate_argo
generate_web
[ -e argo.sh ] && bash argo.sh
[ -e web.sh ] && bash web.sh
wait