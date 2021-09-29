# GEIGER local Storage implementation

This repository contains the implementation for the local storage used in the GEIGER project in dart.

## GEIGER Project
The GEIGER project aims to create a solution for small businesses to protect themselves against cyber threats by constructing an application that calculates a threat score of the current device.

More information can be found under [https://project.cyber-geiger.eu/](https://project.cyber-geiger.eu/)

## For Java developers
We will provide an interoperating java bridge ASAP

## Quick start
### Create an ephemeral storage with a controller for testing puposes 
```Dart
StorageController controller = GenericController('theOwner',DummyMapper());
```
### Create a persistent storage with a controller  
```Dart
StorageController controller = GenericController('theOwner',SqliteMapper('./dbFileName.sqlite'));
```
