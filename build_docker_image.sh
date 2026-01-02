docker build \
    --build-arg HTTP_PROXY="host.docker.internal:7890" \
    --build-arg HTTPS_PROXY="host.docker.internal:7890" \
    --build-arg NO_PROXY="localhost,127.0.0.1,.example.com" \
    --add-host=host.docker.internal:host-gateway \
    -t zheng/codefever-community-lite:latest .