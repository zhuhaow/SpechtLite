## 0.10.0.beta5

### Fixed
- Fixed that ssr with `tls1.2_ticket_auth` will stop unexpectly sometimes.

## 0.10.0.beta3

### Fixed
- Fixed error in changelog.
- Fixed error in alert info.

## 0.10.0.beta1

### Changed
- SpechtLite will be more tolerent of illegal URLs.
- **`ota: true` is obsolete, use the configuration of ShadowsocksR (`protocol: verify_sha1`) instead.**

### Added
- Add support for `http_simple` and `tls1.2_ticket_auth` for SSR.

## 0.9.0

### Fixed
- Fixed a bug relating to reject rule.
- Fixed a thread error when showing an error modal.

### Changed
- Speed test now use gstatic.com instead of google.com.
- Whole UI is rewrote with ReactiveCocoa.

## 0.8.1

### Fixed
- Fixed a bug in SOCKS5 proxy when dealing with IP-based requests.

## 0.8.0

Everything should be much more faster.

### Changed
- Set DNS timeout to 1 second.

### Fixed
- SOCKS5 will work correctly in some circumstances.

## 0.7.1

### Fixed
- Fix crash when OTA is enabled for shadowsocks.
- Fix that the system proxy setting is not updated when switching to a profile with different ports.

## 0.7.0

### Fixed
- Fix `DNSFail` rule.
- Fix autostart at login. You probably need to re-enabled it.
- Fix some circumstances when connection is not disconnected correctly.
- Fix some other bugs.

### Changed
- Now `SpeedAdapter` won't log events of child adapters.

## 0.6.0

### Added
- Add support for OTA, use "ota: true" to enable it.

### Changed
- Convert to swift 3.

### Fixed
- Unset system proxy will set port number to nil.

## 0.5.1

### Added
- Dev channel

## 0.5.0

### Changed
- Update NEKit to 0.7.3
- Bug fix and refinement

## 0.4.9

### Fixed
- Correctly handle empty line in list files.

## 0.4.8

### Fixed 
- Parse error when HTTP header contains non-ascii characters.

## 0.4.7

### Added
- Add "Help" in menu.

## 0.4.6

### Fixed
- Now the privilege permission dialog will only appear for the first time you try to set system proxy. You may have to authorize SpechteLite again.

## 0.4.5

### Fixed
- Fixed a bug that remove configuration is not removed in the menu after reloading.

## 0.4.4

### Fixed
- Now the config names will be sorted correctly.

## 0.4.3

### Changed
- Now the config names will be sorted.

## 0.4.2

### Fixed
- Fixed a bug when the http request has no header field the parsing of the header fails.

## 0.4.1

### Fixed
- SOCKS5 proxy can handle requests with IP address correctly now.

## 0.4.0

### Fixed
- `IPRange` now can handle `/32` IP correctly.
- SOCKS5 proxy can handle client supports more than one auth method.

### Added
- SOCSK5 adapter support!
