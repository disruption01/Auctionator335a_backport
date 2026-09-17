# Auctionator 3.3.5a Backport

Auctionator 336 backported for **World of Warcraft 3.3.5a (build 12340)**.

Original addon by **Borj(amacare)** and **plusmouse**.  
WoW 3.3.5a backport and compatibility work maintained by **Disruption01**.

## Status

**Stable** — Disruption01 release **v1.0**.

This backport is intended to preserve the Auctionator 336 workflow and appearance as closely as practical while adapting its modern Classic FrameXML, APIs, widgets, and Auction House behavior to the legacy 3.3.5a client.

## Features

- Shopping Lists and Recent Searches
- General Auction House search
- Extended Search Options
- Grouped search results and item detail view
- Buying and chain-buy workflows
- Selling with bag item browser
- Stack size, auction duration, deposit, and posting controls
- Current-price and history views
- Cancelling and undercut scanning
- Full Scan
- Import / Export of Shopping Lists
- Export of search results
- 3.3.5a-compatible configuration and Info panels

## Disruption01 Additions

In addition to the compatibility work required for WoW 3.3.5a, this backport includes a configurable fallback price for items that currently have no comparable Auction House listing.

By default, the fallback uses:

```text
vendor price + 20% profit + deposit
```

The following options are available under **Selling: All Items**:

- Automatically define a price when no similar item is being sold as reference
- Percentage of profit based off vendor price
- Cover deposit price

These options are configurable and can be disabled.

## Compatibility

**World of Warcraft 3.3.5a**  
Client build: **12340**

This project targets the legacy 3.3.5a Auction House client. It is not intended for Retail or current official Classic clients.

Private-server behavior can differ between cores. If you report a server-specific issue, include the server/core when known.

## Requirements

- World of Warcraft 3.3.5a, build 12340
- Blizzard Auction House UI (`Blizzard_AuctionUI`)

`LibAHTab` is supported as an optional dependency when present.

## Installation

1. Download the latest release.
2. Extract the archive.
3. Copy the included `Auctionator` folder into your WoW `Interface\AddOns` directory.
4. Start or restart World of Warcraft.
5. Make sure **Auctionator** is enabled in the AddOns list.

The final layout should be:

```text
Interface\AddOns\Auctionator\Auctionator.toc
```

## Configuration / Usage

Open the Auction House and select the Auctionator tabs for Shopping, Selling, Cancelling, and Info.

Addon configuration is available from **Open Addon Options** on the Auctionator Info page or through the standard Interface Options panel.

## Known Issues

- This is a legacy-client backport. Some behavior can vary between 3.3.5a private-server cores even when the client build is the same.
- Upstream Auctionator support channels do **not** provide support for this 3.3.5a backport.

Please report reproducible backport-specific issues through this repository instead.

## Version

**Disruption01 release:** 1.0  
**Upstream base:** Auctionator 336

Release naming convention:

```text
Auctionator-3.3.5a-v1.0
```

## Updating

Replace the existing `Auctionator` addon folder with the version from the new release.

Do not delete `WTF` or SavedVariables unless a specific release note explicitly requires it.

## Credits

Original addon by **Borj(amacare)** and **plusmouse**.  
Original project: https://github.com/TheMouseNest/Auctionator  
Original license: **All Rights Reserved** (as included with the upstream source used by this backport)

WoW 3.3.5a backport and compatibility work by **Disruption01**.

GitHub:  
https://github.com/disruption01

Backport repository:  
https://github.com/disruption01/Auctionator335a_backport

Discord:  
https://discord.gg/eJ5MaVNnBm

## License

The upstream source included in this backport retains its original copyright and license notices.

**Important:** the upstream source bundled with this project is marked **All Rights Reserved**. Public redistribution of modified upstream code is not automatically permitted by that license. Before making this repository or release public, obtain redistribution/modification permission from the relevant copyright holders or otherwise verify that publication is authorized.

The backport does not replace, remove, or reassign upstream authorship or copyright.

## Bug Reports

Please report issues through GitHub Issues:

https://github.com/disruption01/Auctionator335a_backport/issues

Discord is available for discussion and general help:

https://discord.gg/eJ5MaVNnBm

GitHub Issues are preferred for tracked bugs.

When relevant, include:

- Auctionator backport version
- WoW client/build
- Full Lua error
- Reproduction steps
- Screenshots
- Server/core for legacy/private-server-specific problems

## Contributing

Contributions that improve WoW 3.3.5a compatibility are welcome once repository redistribution terms have been confirmed.

Please keep changes focused, preserve upstream attribution, and avoid replacing working legacy compatibility code with unsupported modern APIs.

## Support

Official Discord:

https://discord.gg/eJ5MaVNnBm

If you enjoy my addons and would like to support continued development, maintenance, ports, and backports:

https://linktr.ee/disruption01

Support is completely optional and does not unlock addon functionality.
