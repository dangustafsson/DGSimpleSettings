# DGSimpleSettings
A Core Data backed settings class for iOS

Almost every project needs to easily save and access basic settings. 
If you want to move a step up from NSUserDefaults but don’t feel the need for a full Data Model then maybe DGSimpleSettings is for you.

Relying of KVO you can just add properties to the header file and start using them in your project. It’s safe to add or remove properties between versions of apps.

A small word of warning.
This is just meant to be storing a few bits & bobs. It’s not meant to replace a full Data Model for an app. In order to be versatile it relies on Key Value Observing and Transformable properties. 

Enjoy,
D