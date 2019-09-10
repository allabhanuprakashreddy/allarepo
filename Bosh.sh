#!/bin/sh
wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.0.0/bosh-cli-6.0.0-linux-amd64
mv bosh-cli-* bosh
chmod ugo+r+x bosh
sudo chown root:root bosh
sudo mv bosh /usr/local/bin/bosh
bosh --version