## 0.5.1

New:
- Moved to "lints: ^1.0.1" as a replacement for "pedantic: ^1.11.1" 

Fixed issues:
- Fixes an issue related to the sqlite storage backend and "nulled" ordinals (namely owner)
- Fixes issue with nodes comparison when owner not set (detected in conjunction with sqlite)
- Fixes bad example in README
- Provides better feedback in case of exception

Known issues:
- Serializer is broken (prereq for GeigerAPI)

## 0.5.0

- Initial dart version for consortium internal testing.

