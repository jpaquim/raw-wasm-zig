# jit

Build with:

```sh
zig build-lib -O ReleaseSmall -dynamic -target wasm32-freestanding src/main.zig --export-table --global-base=0 --name jit && cp jit.wasm public/
```
