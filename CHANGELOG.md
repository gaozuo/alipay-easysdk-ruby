# Changelog

## 1.0.4 - 2024-11-26

- Rewrite `Payment::Common::Client#refund` and `#query_refund` to match the PHP EasySDK request pipeline, including Tea-style retries and request signing.
- Restore optional parameter retention between chained calls for full compatibility with the PHP SDK.
- Add typed refund response models (`TradeFundBill`, `PresetPayToolInfo`, `RefundRoyaltyResult`) and hydrate nested data structures identically to PHP.
- Update specs and recorded fixtures to reflect the new refund flow and SDK version string.

## 1.0.3 - 2024-06-06

- Add `payment/app` client and response model to match PHP EasySDK behaviour.
- Align kernel utilities (Config, Factory, EasySDKKernel, PageUtil, AES, Signer, JsonUtil, ResponseChecker) with the PHP implementation.
- Update Payment::Common/Page/Wap clients and models to PHP parity while retaining the custom `payment_url` extension.
- Refresh parity fixtures, expand test coverage, and remove the deprecated `examples/` directory.

## 1.0.2 - 2024-04-15

- Align `payment/page`, `payment/wap`, and `payment/common` dependencies with the PHP EasySDK implementation.
- Extend `Kernel::Config` to support certificate paths, proxy, notify URL, and encryption settings used by PHP clients.
- Introduce certificate environment utilities to derive certificate serial numbers and cached public keys.
- Update `Payment::Common::Client` to honour proxy and SSL settings and improve parity with PHP HTTP behaviour.
- Add comprehensive test coverage for certificate handling, extended configuration, and HTTP proxy behaviour.

## 1.0.1 - 2024-03-01

- Initial public release of the Ruby EasySDK port.
