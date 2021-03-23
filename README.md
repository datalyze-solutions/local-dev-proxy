# Local Traefik Proxy with TLS

Das Projekt stellt eine einfache Möglichkeit dar, einem lokal laufenden Docker Container eine Domain zuzuweisen. Somit kann z.B. der Entwicklungsprozess analog zu einer Online Variante ablaufen, ohne auf einzelne Ports achten zu müssen. Die Standard-Domain lautet `https://local.de`. Ob Services über eine Subdomain oder Pfade freigegeben werden, ist egal.

!!!# Der Proxy läuft als normaler Docker Container und nicht als Swarm Service, da Docker Swarm nicht weiter entwickelt wird.

## Funktionsweise

Der Proxy besteht aus folgenden Containern:

* Traefik Reverse Proxy: lauscht auf Port `80` und `443` und leitet Anfragen an die entsprechenden Container weiter. Das Dashboard ist über https://proxy.local.de aufrufbar.
* mkcert: erzeugt ein Wildcard TLS/SSL Zertifikat im Docker Volume `proxy_certs` bzw. `local-dev-proxy_certs` (je nach Installationmethode).
* hosts-updater: Fügt automatisch freigegebene Domains zur lokalen Datei `/etc/hosts` hinzu. Somit entfällt die manuell Einrichtung eines DNS Servers wie BIND oder dnsmasq.

### Urls

* https://proxy.local.de
* https://proxy.local.de/ping


## Benutzung

Im Verzeichnis befindet sich ein `Makefile`, mit vordefinierten Befehlen. Somit muss nicht jeder Befehl gemerkt werden. Befehle können über `make <befehl>` aufgerufen werden. Die Docker Images werden über `hub.docker.com` gebaut und gehosted. Um ein Image manuell zu pushen, muss vorher ein Login auf `hub.docker.com` erfolgen.

### Installation

#### Lokal

```bash
# installieren
make up

# deinstallieren
make stop
```

#### Einbetten in andere Projekte

Der Proxy enthält ein Installationsscript, welches direkt als Docker Befehl in andere Projekte eingebettet werden kann.

```bash
## Installieren
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro datalyze/local-dev-proxy:installer install
# lokal: make install

## Neustart
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro datalyze/local-dev-proxy:installer restart
# lokal: make stop up

## Deinstallieren
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro datalyze/local-dev-proxy:installer uninstall
# lokal: make uninstall
```

### Webseite bereitstellen

Um einen Container über eine Domain bereitzustellen, muss sich dieser mit dem Proxy im selben Docker Netzwerk befinden. Zusätzlich ist es notwendig, dass bestimmte Container Labels gesetzt sind. Um die Konfiguration übersichtlicher zu gestalten, bietet sich die YAML [extension-fields](https://docs.docker.com/compose/compose-file/#extension-fields) an.

```yaml
version: '2.4'

x-labels-test: &labels-test
  "traefik.enable": "true"
  "traefik.port": "80"
  "traefik.frontend.rule": "Host:my-test.local.de"
  "traefik.frontend.headers.SSLRedirect": "true"

services:
  test:
    image: nginx:stable-alpine
    networks:
      - proxy
    labels:
      << : *labels-test

networks:
  proxy:
    external: true
    name: proxy
```

## HTTP Basic Auth

Um eine Webseite per HTTPS Basic Auth zu schützen, kann dies direkt über die Labels eines Container erfolgen.

```bash
sudo apt update
sudo apt install apache-utils
htpasswd -n -C 31 admin
# ausgabe:
# admin:$apr1$V7ajhSVk$o/BfWK8eNPf8Kn.JiYolr0
```

Die Ausgabe von `htpasswd` kann nicht direkt kopiert werden, da YAML andernfalls die `$` falsch interpretiert. Dazu muss jedes `$` als `$$` escaped werden.

```yaml
"traefik.api.frontend.auth.basic": "admin:$$apr1$$V7ajhSVk$$o/BfWK8eNPf8Kn.JiYolr0"
```


## Test Webseite

Die Datei `test.yml` enthält eine Testwebseite für die Domain https://test.local.de.

```bash
# starten
make test-page

# stoppen
make test-page-stop
```

## Docker Swarm

Der Proxy funktioniert für lokale Single Node Docker Swarm Installationen. Hierfür muss der Proxy zu einem Swarm Netzwerk hinzugefügt werden und die spezifischen Labels zusätzlich als Service Labels gesetzt werden. Da der hosts-updater nicht auf Änderungen von Services reagiert, sondern nur auf Änderungen von Containern, sind sowohl Container als auch Service Labels nötig.

Da Docker Swarm nicht mehr aktiv weiterentwickelt wird und zusätzlich das Handling mit Configs und Secrets das Setup verkomplizieren kann, wird vom Einsatz abgeraten.

* Swarm Network erstellen
  ```bash
  make network-swarm
  ```

* Swarm Network in der Config aktivieren
  ```yaml
  networks:
    proxy:
      external: true
      name: proxy
    proxy-swarm:
      external: true
      name: proxy-swarm
  ```

* Networks des Proxy Service anpassen
  ```yaml
      networks:
        proxy:
        proxy-swarm:
  ```

* Proxy neustarten `make up`


```yaml
version: '3.7'

x-labels-test: &labels-test
  "traefik.enable": "true"
  "traefik.port": "80"
  "traefik.frontend.rule": "Host:my-test.local.de"
  "traefik.frontend.headers.SSLRedirect": "true"

services:
  test:
    image: nginx:stable-alpine
    networks:
      - proxy
    labels:
      << : *labels-test
    deploy:
      labels:
        << : *labels-test

networks:
  proxy:
    external: true
    name: proxy-swarm
```

## FAQ

Wenn der Proxy ohne den hosts-updater verwendet werden soll, muss lokal ein DNS Server installiert und entsprechend konfiguriert werden.

### lokaler DNS Server (dnsmasq)

Diese Variante bietet die Vorteile, dass Wildcard Auflösungen gesetzt werden können und der DNS Service leicht deaktivierbar ist.

Wird `systemd` verwendet, was bei vielen neueren Linux Distributionen (z.B. ab Ubuntu 16.04) der Fall ist, kollidiert die Installation mit dem `systemd-resolver` Service. Hier müssen dann umfangreichere Änderungen durchgeführt werden.

#### Ohne Systemd

```bash
sudo apt update
sudo apt install dnsmasq
echo "address=/local.com/127.0.0.1" | sudo tee -a /etc/dnsmasq.conf
sudo service dnsmasq restart
```

#### Mit Systemd

Folgende Anweisungen basieren auf folgender [Anleitung](https://unix.stackexchange.com/questions/304050/how-to-avoid-conflicts-between-dnsmasq-and-systemd-resolved/516808#516808).

```bash
sudo apt update
sudo apt install dnsmasq

sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/noresolved.conf << EOF
[Resolve]
DNSStubListener=no
EOF
sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved

sudo rm /etc/resolv.conf
sudo tee /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF

sudo tee /etc/NetworkManager/conf.d/disableresolv.conf << EOF
[main]
dns=none
EOF
sudo systemctl restart NetworkManager

sudo tee /etc/dnsmasq.d/nmresolv.conf << EOF
resolv-file=/var/run/NetworkManager/resolv.conf
EOF

sudo systemctl stop dnsmasq
sudo systemctl start dnsmasq

echo "address=/local.com/127.0.0.1" | sudo tee -a /etc/dnsmasq.conf
```


### Docker installieren

Die mit in der jeweiligen Distribution mitgelieferten Pakete für Docker sind nicht auf dem aktuellen Stand und enthalten oft Änderungen, die den korrekten Betrieb stören können. Besser ist die Befolgung der [offiziellen Anleitung](https://docs.docker.com/install/linux/docker-ce/).

Desweiteren sollte `docker-compose` ebenfalls aus der [offiziellen Anleitung](https://docs.docker.com/compose/install/) installiert werden.


### Docker Login schlägt fehlt

Schlägt `docker login hub.docker.com` fehl und es ist sichergestellt, dass die Logindaten korrekt sind, kann die Installation der folgenden Pakete Abhilfe schaffen: `sudo apt install gnupg2 pass`.
