# VPS machine initializer

My own stuff that is to be run under root when initializing new machine.

## Current delpoyment flow

Connect to the new machine as root and execute the following:

```bash
git clone https://github.com/texhobeer/vps-initializer.git && ./vps-initializer/setup.sh
```

It will ask for username to create, install and setup docker.
