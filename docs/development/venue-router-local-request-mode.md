
# Venue Router Setup for Local Request Mode

This document is a planning guide for the local request-mode router flow. It does not change any network device.

## Preview-only setup notes

1. Host machine runs the karaoke host service on the venue LAN.
2. Guests scan a venue QR code that points to the request web app route.
3. Local mode label tells the guest they are connected through the venue network.
4. Cloud mode label tells the guest fallback is available when local routing is unavailable.
5. QR fallback route can be shown on the shared tablet/kiosk display.

## Safety boundary

This document does not open router ports, configure DNS, change firewall rules, run DHCP changes, expose a public endpoint, submit requests, or connect to a live venue router.
