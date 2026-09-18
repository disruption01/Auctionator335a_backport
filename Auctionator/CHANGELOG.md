# Auctionator

## 1.0.1

- Removed Auctionator's fake global Blizzard `Settings` API shim on WoW 3.3.5a.
- Registered Auctionator configuration panels directly through the native legacy `InterfaceOptions_*` API.
- Removed dependency on the modern/fake `SettingsPanel` global.
- Prevents unrelated addons from incorrectly detecting a modern Settings API and entering unsupported code paths.

## [336](https://github.com/TheMouseNest/Auctionator/tree/336) (2026-08-26)
[Full Changelog](https://github.com/TheMouseNest/Auctionator/compare/335...336) 

- Prevent showing auction prices on WuE gear  
