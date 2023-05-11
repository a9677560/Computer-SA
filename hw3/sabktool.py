#!/usr/bin/env python3

import os 
import sys

def create():
    if len(sys.argv) < 3:
        print("Missing argument")
        sys.exit()

    file_system = "sa_pool/data"
    snapshot_name = sys.argv[2]
    command = f"zfs snapshot {file_system}@{snapshot_name}"

    os.system(command)

def remove():
    if len(sys.argv) < 3:
        print("Missing argument")
        sys.exit()

    file_system = "sa_pool/data"
    snapshot_name = sys.argv[2]
    
    if snapshot_name == "all":
        command = f"zfs destroy -r {file_system}@%"
    else:
        command = f"zfs destroy {file_system}@{snapshot_name}"

    os.system(command)
    
def list():
    os.system("zfs list -r -t snapshot -o name /sa_data")

def roll():
    if len(sys.argv) < 3:
        print("Missing argument")
        sys.exit()
        
    file_system = "sa_pool/data"
    snapshot_name = sys.argv[2]
    command = f"zfs rollback -r {file_system}@{snapshot_name}"
    
    os.system(command)

def logrotate():
    os.system("logrotate /etc/logrotate.d/fakelog_py")

def default_func():
    print("未知的選項")

options = {
    "create": create,
    "remove": remove,
    "list": list,
    "roll": roll,
    "logrotate": logrotate,
}

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('no argument')
        sys.exit()
  
    # 根據引數的值執行相應的函數，如果引數的值不在字典中，則執行 default_func
    # 最後使用 () 來調用此函數
    options.get(sys.argv[1], default_func)()
