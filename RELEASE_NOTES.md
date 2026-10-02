# KidTime v0.1.1

This is a bugfix release for the Xiaomi BE6500 Router Adapter.

## Fixed

- Added the required `model=0` parameter when calling Xiaomi's `edit_device` API.
- Without this parameter, the API could return `code:0` without actually adding the device to the blacklist.
- Verified on the live BE6500 environment that both configured 2.4 GHz and 5 GHz device MAC addresses are blocked and restored correctly.

## Notes

No changes were made to KidTime timing logic, KidBlock logic, or the Web Panel.
