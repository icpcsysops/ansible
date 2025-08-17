#!/usr/bin/python
import re
from ansible.plugins.action import ActionBase
from ansible.utils.display import Display
from datetime import datetime
from pathlib import Path
from github import Github
from requests_cache import DO_NOT_CACHE, get_cache, install_cache
import requests

display = Display()

# Hook magic caching into github
install_cache(
    cache_control=True,
    urls_expire_after={
        '*.github.com': 360,  # Placeholder expiration; should be overridden by Cache-Control
        '*': DO_NOT_CACHE,  # Don't cache anything other than GitHub requests
    },
    backend='filesystem',
    cache_name='/root/ansible/.github_release_cache'
)

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):
        super(ActionModule, self).run(tmp, task_vars)
        self.version = self._task.args.get('version', 'latest')
        self.repo = self._task.args.get('repo')
        self.token = self._task.args.get('token', None)
        self.cache = self._task.args.get('cache', True)
        self.asset = self._task.args.get('asset')


        ret = dict()
        if not self.repo or not self.asset or not self.version:
            ret['failed'] = True
            ret['msg'] = "Missing required parameters"
            return ret


        gh = Github(self.token)
        ghrepo = gh.get_repo(self.repo)
        release = None

        if self.version == 'latest':
            release = ghrepo.get_latest_release()
        elif self.version == 'latest-unreleased':
            release = ghrepo.get_releases()[0]
        else:
            release = ghrepo.get_release(self.version)

        for asset in release.get_assets():
            if self.asset and not re.match(self.asset, asset.name):
                continue

            display.warning(f"Found matching asset: {asset.name}")
            ret['version'] = release.tag_name
            ret['asset'] = asset.name
            ret['url'] = asset.browser_download_url
            ret['size'] = asset.size
            # ret['digest'] = asset.digest

            # See if we already have this file
            cache_path = Path(task_vars['inventory_dir']) / 'internet' / self.repo / asset.name
            if self.cache:
                cache_path.parent.mkdir(parents=True, exist_ok=True)
                if cache_path.exists() and cache_path.stat().st_size == asset.size:
                    ret['cached'] = True
                    ret['cache_path'] = str(cache_path)
                    break
                else:
                    display.warning(f"Cache miss for {asset.name}. Downloading to {cache_path}")

            # Download the asset to a file
            with cache_path.open('wb') as f:
                f.write(requests.get(asset.browser_download_url).content)

            # Also doesn't exist in the version we have via apt
            # currently broken, see: https://github.com/PyGithub/PyGithub/issues/3315
            # asset.download_asset(cache_path, chunk_size=8192)
            ret['cache_path'] = str(cache_path)
            break

        if 'asset' not in ret:
            ret['failed'] = True
            ret['msg'] = f"No assets matched pattern: {self.asset}"
            return ret

        # Copy to remote system using proper action plugin file transfer
        dest_path = self._task.args.get('dest')

        # Transfer the file from controller to target
        transferred_file = self._transfer_file(ret['cache_path'], dest_path)

        # Use the copy module to handle final placement and permissions
        module_args = {
            'src': transferred_file,
            'dest': dest_path,
            'remote_src': True,  # File is now on the target machine
        }
        module_return = self._execute_module(module_name='copy',
                                             module_args=module_args,
                                             task_vars=task_vars, tmp=tmp)

        # Merge ret and module_return
        ret.update({k:v for k,v in module_return.items() if k in ('failed', 'changed', 'msg', 'dest')})

        return ret


# Structure:
# Make api requests to find the release information
# Fetch all assets for the release we are after
# Match the assets against what we were asked to fetch (using regex)
# Use the copy module to copy the asset from our cache to the host
# Return the asset filename
# Cache things in ./internet
