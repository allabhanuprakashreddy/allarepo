wget https://github.com/cloudfoundry/bosh-cli/releases/download/v6.0.0/bosh-cli-6.0.0-linux-amd64
mv bosh-cli-* bosh
chmod ugo+r+x bosh
sudo chown root:root bosh
sudo mv bosh /usr/local/bin/bosh
bosh --version

sudo apt update
sudo apt install ruby

sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt1-dev libxml2-dev libssl-dev libreadline7 libreadline-dev libyaml-dev libsqlite3-dev sqlite3

git clone https://github.com/cloudfoundry/bosh-deployment.git

bosh create-env bosh-deployment/bosh.yml \
    --vars-store=creds.yml \
    -o bosh-deployment/azure/cpi.yml \
    -v director_name=bosh-1 \
    -v internal_cidr=10.244.0.0/20 \
    -v internal_gw=10.244.0.1 \
    -v internal_ip=10.244.0.6 \
    -v vnet_name=boshnet \
    -v subnet_name=bosh \
    -v subscription_id=0c86d3aa-737e-4a12-9a85-a09b0c59bf34 \
    -v tenant_id=4ab3bdc1-a252-4068-a6bd-6f6b33323733 \
    -v client_id=478bb486-ab26-4bcd-8a03-262f83ec4c66 \
    -v client_secret=309ed890-4ee2-47f9-aede-437ed8d04145 \
    -v resource_group_name=bosh-res-group \
    -v storage_account_name=myboshstore1 \
    -v default_security_group=nsg-bosh 

bosh alias-env bosh-1 -e 10.244.0.6 --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca)
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh int ./creds.yml --path /admin_password)
export BOSH_ENVIRONMENT=bosh-1
export BOSH_CA_CERT=$(bosh int ./creds.yml --path /director_ssl/ca)
bosh login

export CREDHUB_SERVER=https://10.244.0.6
export CREDHUB_CLIENT=credhub-admin
export CREDHUB_SECRET=$(bosh interpolate ./creds.yml --path=/admin_password)

git clone https://github.com/cloudfoundry/cf-deployment

bosh update-cloud-config cf-deployment/iaas-support/bosh-lite/cloud-config.yml

export STEMCELL_VERSION=$(bosh int cf-deployment.yml --path '/stemcells/alias=default/version')
bosh upload-stemcell  https://bosh.io/d/stemcells/bosh-azure-hyperv-ubuntu-xenial-go_agent?v=456.14

bosh update-runtime-config <(bosh int bosh-deployment/runtime-configs/dns.yml --vars-store deployment-vars.yml) --name dns

bosh -d cf deploy cf-deployment/cf-deployment.yml \
  -o cf-deployment/operations/bosh-lite.yml \
  --vars-store deployment-vars.yml \
  -v system_domain=bosh-lite.com \
  -o cf-deployment/operations/use-compiled-releases.yml