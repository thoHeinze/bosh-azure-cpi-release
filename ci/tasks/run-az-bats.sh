#!/usr/bin/env bash

set -e

: ${INFRASTRUCTURE:?}
: ${STEMCELL_NAME:?}
: ${BAT_INFRASTRUCTURE:?}
: ${BAT_NETWORKING:?}
: ${BAT_RSPEC_FLAGS:?}
: ${AZURE_BATS_ZONE:?}

source pipelines/shared/utils.sh
source /etc/profile.d/chruby.sh
chruby 3.1.0

metadata="$( cat environment/metadata )"
mkdir -p bats-config
bosh int bosh-cpi-src/ci/tasks/az-bats-spec.yml \
  -v "stemcell_name=${STEMCELL_NAME}" \
  -v "availability_zone=${AZURE_BATS_ZONE}"  \
  -l environment/metadata > bats-config/bats-config.yml

source director-state/director.env
export BAT_PRIVATE_KEY="$( creds_path /jumpbox_ssh/private_key )"
export BAT_DNS_HOST="${BOSH_ENVIRONMENT}"
export BAT_STEMCELL=$(realpath stemcell/*.tgz)
export BAT_DEPLOYMENT_SPEC=$(realpath bats-config/bats-config.yml)
export BAT_BOSH_CLI=$(which bosh)

ssh_key_path=/tmp/bat_private_key
echo "$BAT_PRIVATE_KEY" > $ssh_key_path
chmod 600 $ssh_key_path
export BOSH_GW_PRIVATE_KEY=$ssh_key_path

pushd bats
  bundle install
  bundle exec rspec spec $BAT_RSPEC_FLAGS
popd
