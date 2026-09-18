# Changelog

All notable Disruption01 changes to the WoW 3.3.5a backport are documented here.

## 1.0.1

- Removed the fake global Blizzard `Settings` API shim from the 3.3.5a compatibility layer.
- Auctionator configuration panels now register directly through the native legacy `InterfaceOptions_*` API.
- Removed the dependency on a modern/fake `SettingsPanel` global.
- Prevents unrelated addons from incorrectly detecting a modern Settings API and entering unsupported code paths.

## 1.0

- First stable public Disruption01 release of the Auctionator 336 backport for World of Warcraft 3.3.5a build 12340.
