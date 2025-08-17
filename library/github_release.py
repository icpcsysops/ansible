#!/usr/bin/python
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
from ansible.plugins.action import ActionBase
from datetime import datetime
import urllib.request
import urllib.error
import json

DOCUMENTATION = r'''
---
module: github_release

short_description: Fetches and caches a GitHub release asset
version_added: "1.0.0"

description:
    - Downloads GitHub release assets and caches them locally
    - Supports pattern matching for asset names using regex
    - Automatically copies the asset to the target destination

options:
    repo:
        description: GitHub repository in format 'owner/repo'
        required: true
        type: str
    version:
        description:
            - Version of the release to fetch
            - Use 'latest' for the latest stable release
            - Use 'latest-unreleased' for the most recent release (including pre-releases)
            - Use specific version tag (e.g. 'v1.0.0')
        required: false
        type: str
        default: latest
    asset:
        description:
            - Regex pattern to match asset names
            - First matching asset will be downloaded
        required: true
        type: str
    dest:
        description: Destination path on the target host
        required: true
        type: str
    cache:
        description: Whether to cache downloaded assets locally
        required: false
        type: bool
        default: true
    token:
        description: GitHub personal access token for authentication
        required: false
        type: str

author:
    - ICPC Systems Operations
'''

EXAMPLES = r'''
# Download latest CDS release asset
- name: Fetch latest CDS
  github_release:
    repo: icpctools/icpctools
    asset: ".*wlp.*"
    version: latest
    dest: /tmp/cds.zip

# Download specific version
- name: Fetch specific CDS version
  github_release:
    repo: icpctools/icpctools
    version: v2.5.1082
    asset: "wlp.CDS-.*\\.zip"
    dest: /tmp/wlp.CDS-2.5.1082.zip

# Download with authentication token
- name: Fetch from private repo
  github_release:
    repo: myorg/private-repo
    asset: "release-.*\\.tar\\.gz"
    version: latest
    dest: /opt/app/release.tar.gz
    token: "{{ github_token }}"
    cache: false
'''

RETURN = r'''
asset:
    description: Name of the downloaded asset file
    type: str
    returned: success
    sample: 'wlp.CDS-2.5.1082.zip'
version:
    description: Version tag of the release
    type: str
    returned: success
    sample: 'v2.5.1082'
url:
    description: Download URL of the asset
    type: str
    returned: success
    sample: 'https://github.com/icpctools/icpctools/releases/download/v2.5.1082/wlp.CDS-2.5.1082.zip'
size:
    description: Size of the asset in bytes
    type: int
    returned: success
    sample: 72366764
cache_path:
    description: Local cache path where the asset is stored
    type: str
    returned: success
    sample: '/mnt/ansible/internet/icpctools/icpctools/wlp.CDS-2.5.1082.zip'
cached:
    description: Whether the asset was already cached (not downloaded)
    type: bool
    returned: success
    sample: true
dest:
    description: Destination path on the target host
    type: str
    returned: success
    sample: '/tmp/foo2'
changed:
    description: Whether the target file was changed
    type: bool
    returned: always
    sample: false
failed:
    description: Whether the operation failed
    type: bool
    returned: failure
    sample: false
msg:
    description: Error message if operation failed
    type: str
    returned: failure
    sample: 'No assets matched pattern: .*nonexistent.*'
'''
