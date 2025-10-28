# Changelog

## 1.0.2 - 2024-04-15

- Align `payment/page`, `payment/wap`, and `payment/common` dependencies with the PHP EasySDK implementation.
- Extend `Kernel::Config` to support certificate paths, proxy, notify URL, and encryption settings used by PHP clients.
- Introduce certificate environment utilities to derive certificate serial numbers and cached public keys.
- Update `Payment::Common::Client` to honour proxy and SSL settings and improve parity with PHP HTTP behaviour.
- Add comprehensive test coverage for certificate handling, extended configuration, and HTTP proxy behaviour.

## 1.0.1 - 2024-03-01

- Initial public release of the Ruby EasySDK port.
