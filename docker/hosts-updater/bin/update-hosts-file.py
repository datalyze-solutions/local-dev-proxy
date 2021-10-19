#!/usr/bin/env python3
# coding=utf-8

from clize import run
import os
import sys
import shutil
from datetime import datetime
import glob
from pathlib import Path
import logging
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

__version__ = "0.0.1"

placeholder = "# docker-gen"


def get_default_hosts_content(hostname):
    if hostname:
        return f"""
127.0.1.1 {hostname}
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

    """
    else:
        return f"""
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

    """

# howto reliable persist files:
# https://blog.gocept.com/2013/07/15/reliable-file-updates-with-python/


def version():
    """Show the version"""
    return __version__


def get_additional_content(additional_files_path):
    with open(additional_files_path, 'r') as additional_file:
        additional_file.seek(0)
        additional_content = additional_file.read()
    return additional_content


def cmd_cleanup(hosts_file_path, *, hostname="localhost", backup_dir="/backups"):
    """Cleanes the hosts file

    :param hosts_file_path
    """
    update_hosts_file(hosts_file_path, additional_content=None,
                      hostname=hostname, backup_dir=backup_dir)


def cmd_update(hosts_file_path, additional_files_path, *, hostname="localhost", backup_dir="/backups"):
    """Updates the hosts file

    :param hosts_file_path
    :param additional_files_path
    """
    additional_content = get_additional_content(additional_files_path)
    update_hosts_file(hosts_file_path, additional_content,
                      hostname, backup_dir)


def cmd_backup(hosts_file_path, backup_dir):
    Path(backup_dir).mkdir(parents=True, exist_ok=True)

    if Path(hosts_file_path).stat().st_size == 0:
        logging.error("Empty hosts file detected. Don't backup.")
        return backup_dir

    date_string = datetime.now().isoformat().replace(':', '-')
    target_path = Path(backup_dir, f"hosts_{date_string}")
    shutil.copyfile(Path(hosts_file_path), target_path)
    return backup_dir


def get_latest_backup(backup_dir):
    backup_files = sorted(
        glob.glob(str(Path(backup_dir, "hosts*"))), reverse=True)

    latest_backup_path = safe_list_get(backup_files, 0, None)
    if latest_backup_path:
        return Path(latest_backup_path)
    else:
        raise IOError


def safe_list_get(l, idx, default):
    try:
        return l[idx]
    except IndexError:
        return default


def update_hosts_file(hosts_file_path, additional_content=None, hostname="localhost", backup_dir="/backups"):

    with open(hosts_file_path, 'a+') as hosts_file:
        hosts_file.seek(0)
        hosts_file_lines = hosts_file.readlines()

        cleaned_hosts_file_content = [
            line for line in hosts_file_lines if placeholder not in line
        ]
        cleaned_hosts_file_content = "".join(cleaned_hosts_file_content)

        # take care, that we never ever have an empty hosts file!
        # use backups or default in that case
        if not cleaned_hosts_file_content:
            logging.error("Empty hosts file detected")
            try:
                latest_backup_path = get_latest_backup(backup_dir)
                logging.info("Restoring from backups.")
                with open(latest_backup_path, 'r') as latest_backup_file:
                    latest_backup_content = latest_backup_file.read()
            except:
                latest_backup_content = None

            if latest_backup_content:
                cleaned_hosts_file_content = latest_backup_content
            else:
                logging.info(
                    "Restoring from backups failed. Using default hosts content.")
                cleaned_hosts_file_content = get_default_hosts_content(
                    hostname)
            print(cleaned_hosts_file_content)

        # truncate full file
        hosts_file.seek(0)
        if cleaned_hosts_file_content:
            hosts_file.truncate()
            hosts_file.write(cleaned_hosts_file_content)

        if additional_content:
            hosts_file.write(additional_content)

        # take care that the file is persisted to disk, not in cache only
        hosts_file.flush()
        os.fdatasync(hosts_file)


def main():
    """Test"""
    run(
        {
            'clean': cmd_cleanup,
            'update': cmd_update,
            'backup': cmd_backup
        },
        alt=[
            version,
        ]
    )


if __name__ == "__main__":
    main()
