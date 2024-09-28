#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

_git_clone_or_pull() {
    repo_dir="$1"
    repo_url="${2:-}"

    if [[ -z "$repo_url" ]]; then
        repo_url=$(ynh_read_manifest "upstream.code")
    fi

    if [ -d "$repo_dir" ]; then
        ynh_exec_as_app git -C "$repo_dir" fetch --quiet
    else
        ynh_exec_as_app git clone "$repo_url" "$repo_dir" --quiet
    fi
    ynh_exec_as_app git -C "$repo_dir" checkout master --quiet
    ynh_exec_as_app git -C "$repo_dir" pull origin master --quiet
}


update_appstore_cache() {
    ynh_exec_as_app curl -so .cache/apps.json https://app.yunohost.org/default/v3/apps.json

    _git_clone_or_pull .cache/apps https://github.com/YunoHost/apps.git
    _git_clone_or_pull .cache/tools https://github.com/YunoHost/apps-tools.git

    if [ ! -d ".cache/tools/venv" ]; then
        ynh_exec_as_app python3 -m venv .cache/tools/venv
    fi
    ynh_exec_as_app .cache/tools/venv/bin/pip install -r requirements.txt >/dev/null

    ynh_exec_as_app .cache/tools/venv/bin/python3 .cache/tools/app_caches.py -l .cache/apps/ -c .apps_cache -d -j20

    venv/bin/python3 fetch_main_dashboard.py 2>&1 | grep -v 'Following Github server redirection'

    venv/bin/python3 fetch_level_history.py
}
