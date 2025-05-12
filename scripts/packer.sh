#!/bin/bash

main() {
    local packer_file
    packer_file='terraform/hcloud-microos-snapshots.pkr.hcl'

    if [[ -z "$HCLOUD_TOKEN" ]]; then
        echo "HCLOUD_TOKEN is not set. Please get and API token with read/write access and set it in your environment, e.g. 'export HCLOUD_TOKEN=your_token_here'."
        exit 1
    fi

    packer init "$packer_file"
    packer build "$packer_file"
}

main
