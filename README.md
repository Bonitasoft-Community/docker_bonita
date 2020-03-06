Bonitasoft docker images
=========================

Each folder contains the source of the docker images for each minor version of Bonita.


## Build 

```
./build.sh -- $BONITA_MINOR_VERSION
```


## Test 

Tests uses [goss](https://github.com/aelsabbahy/goss)

```
cd test && ./runTests.sh ../$BONITA_MINOR_VERSION
```
