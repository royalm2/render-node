#!/usr/bin/env bash

# 设置各变量
#WSPATH=${WSPATH:-'argo'}
#UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}

download_app() {
  if [[ ! -e /app/web.js ]]; then
    wget -O /app/web.js https://raw.githubusercontent.com/lililiwuming/nnn/main/mysql
    chmod +x /app/web.js
  fi
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  if [[ -n "\${ARGO_AUTH}" ]]; then
    [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > tunnel.json && echo -e "tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)\ncredentials-file: /app/tunnel.json" > tunnel.yml
  fi
}

argo_type
ABC
}

generate_pm2_file() {
  ARGS="-c https://raw.githubusercontent.com/lililiwuming/nnn/main/node.json"
  
  if [[ -n "${ARGO_AUTH}" ]]; then
    [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run"

    cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run",
          "args":"${ARGS}"        
      },
      {
          "name":"argo",
          "script":"cloudflared",
          "args":"${ARGO_ARGS}"
      }
  ]
}
EOF
  else  
    cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/app/web.js run"
          "args":"${ARGS}"
      }
  ]
}
EOF
  fi
}

download_app
generate_argo
generate_pm2_file
[ -e argo.sh ] && bash argo.sh
[ -e ecosystem.config.js ] && pm2 start