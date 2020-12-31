Bonitasoft docker images (DEPRECATED)
===

Each folder contains the source of the docker images for each minor version of Bonita.

:warning: **Attention**: from version 7.11.3 and above, this docker images sources are part of the
[bonita-distrib](https://github.com/bonitasoft/bonita-distrib/tree/master/docker) Github repository.  
This repository will be abandoned in benefits of https://github.com/bonitasoft/bonita-distrib.

## Build

```
./build.sh -- $BONITA_MINOR_VERSION
```


## Test

Tests uses [goss](https://github.com/aelsabbahy/goss)

```
cd test && ./runTests.sh ../$BONITA_MINOR_VERSION
```
