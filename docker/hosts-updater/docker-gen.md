docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock:ro -v /home/mludwig/Dokumente/Projekte/Datalyze/local-dev-proxy/:/templates:ro alpine sh
--> install docker-gen
wget https://github.com/jwilder/docker-gen/releases/download/0.7.4/docker-gen-alpine-linux-amd64-0.7.4.tar.gz
tar xf docker-gen-alpine-linux-amd64-0.7.4.tar.gz
mv docker-gen /usr/local/bin
docker-gen -watch -notify "echo 'NEW'" /tmp/nginx.tmpl  /tmp/output
