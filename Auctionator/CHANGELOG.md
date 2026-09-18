# Auctionator

## 1.0.2

- Added compatibility fixes for Whitemane-derived 3.3.5a behavior without changing the established stock 3.3.5a paths.
- Accept localized item subclass names returned as strings instead of assuming numeric subclass IDs.
- Fill missing methods individually on partial `ColorMixin` implementations, including `WrapTextInColorCode`.
- Normalize item-quality color markup to prevent malformed `|c` prefixes in Shopping results.
- Fall back to the auction hyperlink for item names when the client item cache has not populated them yet.
- Added a native 3.3.5a minimap button with settings, credits and Disruption01/upstream links.
- Updated the minimap button to use the native circular minimap artwork.

## 1.0.1

- Removed Auctionator's fake global Blizzard `Settings` API shim on WoW 3.3.5a.
- Registered Auctionator configuration panels directly through the native legacy `InterfaceOptions_*` API.
- Removed dependency on the modern/fake `SettingsPanel` global.
- Prevents unrelated addons from incorrectly detecting a modern Settings API and entering unsupported code paths.

## [336](https://github.com/TheMouseNest/Auctionator/tree/336) (2026-08-26)
[Full Changelog](https://github.com/TheMouseNest/Auctionator/compare/335...336) 

- Prevent showing auction prices on WuE gear  
