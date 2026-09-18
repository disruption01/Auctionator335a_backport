# Auctionator 3.3.5a Backport

Auctionator 336 adapted for the legacy World of Warcraft 3.3.5a Auction House client.

**Original addon by Borj(amacare) and plusmouse.**  
**World of Warcraft 3.3.5a backport and compatibility work by Disruption01.**

## Release

**Version 1.0.1** is the current Disruption01 release for WoW 3.3.5a.

This project keeps the original Auctionator workflow and appearance as closely as practical while adapting modern Classic FrameXML, APIs, widgets, and Auction House behavior to the 3.3.5a client.

## Compatibility

World of Warcraft 3.3.5a  
Client build: **12340**

This repository targets the legacy 3.3.5a client. It is not the upstream Auctionator project and should not be used as a support target for current Retail or official Classic clients.

## Features

The backport preserves the major Auctionator 336 workflows, including:

- Shopping Lists and Recent Searches
- General and extended item searches
- Auction result grouping and item detail views
- Buying and chain-buy workflows
- Selling with bag item browsing
- Stack size, duration, deposit, and posting controls
- Cancelling and undercut scanning
- Import/export of Shopping Lists and search results
- Legacy Auction House compatibility for WoW 3.3.5a
- 3.3.5a-compatible configuration and Info panels

### 3.3.5a backport enhancement

When no similar item is currently listed on the Auction House, the Selling tab can automatically define a fallback price using the item's vendor value.

Default formula:

```text
vendor price + 20% profit + deposit
```

The profit percentage and deposit coverage are configurable in **Selling: All Items**.

## Installation

1. Download or clone this repository.
2. Copy the included `Auctionator` folder into your WoW `Interface\AddOns` directory.
3. Start or restart World of Warcraft.
4. Make sure **Auctionator** is enabled in the AddOns list.

The final layout should be:

```text
Interface\AddOns\Auctionator\Auctionator.toc
```

## Repository

https://github.com/disruption01/Auctionator335a_backport

Official Discord:

https://discord.gg/eJ5MaVNnBm

Please report issues with this **3.3.5a backport** in this repository rather than through the upstream Auctionator support channels.

## Credits

### Original addon

Auctionator by **Borj(amacare)** and **plusmouse**.

The original project, copyright notices, and existing license information are preserved in this repository.

### 3.3.5a backport

Backport, compatibility work, maintenance, testing fixes, and 3.3.5a-specific adaptations by **Disruption01**.

https://github.com/disruption01

Discord:

https://discord.gg/eJ5MaVNnBm

## Bug Reports

Please report tracked bugs through GitHub Issues:

https://github.com/disruption01/Auctionator335a_backport/issues

Discord is intended for discussion and general help.

## Support

Official Discord:

https://discord.gg/eJ5MaVNnBm

If you enjoy my addons and would like to support continued development, maintenance, ports, and backports:

https://linktr.ee/disruption01

Support is completely optional and does not unlock addon functionality.

## License

The upstream source included in this repository retains its original copyright and license notices. See [`LICENSE`](LICENSE).

Backport-specific changes do not replace or remove the original authorship, copyright notices, or licensing terms.
