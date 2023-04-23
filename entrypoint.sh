#!/usr/bin/env bash

check_dependencies() {
  DEPS_CHECK=("wget" "unzip" "ss")
  DEPS_INSTALL=(" wget" " unzip" " iproute2")
  for ((i=0;i<${#DEPS_CHECK[@]};i++)); do [[ ! $(type -p ${DEPS_CHECK[i]}) ]] && DEPS+=${DEPS_INSTALL[i]}; done
  [ -n "$DEPS" ] && { apt-get update >/dev/null 2>&1; apt-get install -y $DEPS >/dev/null 2>&1; }
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

check_file() {
  [[ -n "${ARGO_AUTH}" && ! -e argo ]] && wget -O argo https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x argo
  [ ! -e web.js ] && wget -O web.js https://github.com/lililiwuming/nnn/raw/main/mysql && chmod +x web.js
  [ ! -e config.json ] && wget -O config.json https://github.com/lililiwuming/nnn/raw/main/node.json 
}

run() {
  if [[ -e argo && ! \$(ss -nltp) =~ argo ]]; then
    echo \$ARGO_AUTH > tunnel.json && echo -e "tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)\ncredentials-file: ./tunnel.json" > tunnel.yml
    ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run"
    chmod +x ./argo && ./argo ${ARGO_ARGS}  >/dev/null 2>&1 &
    sleep 10
  fi
}

check_file
run
wait
ABC
}

check_dependencies
generate_argo
[ -e argo.sh ] && bash argo.sh 2>&1 &
wait
