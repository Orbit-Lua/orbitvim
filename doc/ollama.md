# Ollama Setup (Arch Linux)

OrbitVim uses
[Minuet](https://github.com/milanglacier/minuet-ai.nvim) with Ollama's
OpenAI-compatible FIM endpoint and the
`qwen2.5-coder:7b-base-q6_K` model. The setup below uses the
[`ollama-vulkan-bin`](https://aur.archlinux.org/packages/ollama-vulkan-bin) AUR
package.

## Install the Vulkan runtime and Ollama

Install the Vulkan ICD for the GPU. This AMD/RADV example matches the tested
configuration; use the appropriate Vulkan driver package for other vendors.
Refer to [Ollama's Vulkan hardware
notes](https://docs.ollama.com/gpu#vulkan-gpu-support) when selecting a driver:

```bash
sudo pacman -S --needed vulkan-radeon vulkan-tools
vulkaninfo --summary
```

`vulkaninfo` must list the intended GPU before continuing. Install Ollama with
an AUR helper after reviewing the PKGBUILD:

```bash
yay -S ollama-vulkan-bin
```

The split AUR package also installs `ollama-bin` and provides:

- `/usr/bin/ollama`
- `ollama.service`, running as the `ollama` system user
- `/etc/ollama.conf` for general server settings
- `/etc/ollama-vulkan.conf` for Vulkan settings
- `/var/lib/ollama` as both the service home and model store

## Select the Vulkan GPU

The package enables Vulkan through `OLLAMA_VULKAN=1`. Its default visible-device
list may include GPU indexes that do not exist on the current machine. Match the
`GPU<n>` number from `vulkaninfo --summary` and edit:

```bash
sudoedit /etc/ollama-vulkan.conf
```

For a system where the discrete GPU is `GPU0`, keep these settings:

```ini
OLLAMA_VULKAN=1
GGML_VK_VISIBLE_DEVICES=0

# Recommended for low-latency completion after the first model load.
OLLAMA_KEEP_ALIVE=-1
```

Do not copy index `0` blindly on a multi-GPU machine. An invalid index can make
Vulkan discovery fail and cause Ollama to fall back to CPU. Package upgrades
preserve this config as a pacman backup file; review an
`/etc/ollama-vulkan.conf.pacnew` if one is created.

The packaged service already grants `CAP_PERFMON`. If logs show a permission
error for an AMD render device, add the service user to the `render` group and
restart the service:

```bash
sudo usermod -aG render ollama
sudo systemctl restart ollama.service
```

## Start Ollama and install the model

Keep `OLLAMA_HOST="http://127.0.0.1:11434"` in `/etc/ollama.conf`. Tailscale
Serve will proxy this loopback listener, so Ollama does not need to listen on
the LAN or every interface. Keep `OLLAMA_CONTEXT_LENGTH=4096` as well; it matches
Minuet's configured context window. Increasing it uses more VRAM and should be
done together with the Minuet setting.

Enable the service and inspect its status:

```bash
sudo systemctl enable --now ollama.service
systemctl status ollama.service
curl http://127.0.0.1:11434/api/version
```

After changing either Ollama config file, restart the service:

```bash
sudo systemctl restart ollama.service
```

Pull the exact model configured by OrbitVim:

```bash
ollama pull qwen2.5-coder:7b-base-q6_K
ollama list
```

This is the base FIM model, not an instruction-tuned chat model. The current
quantized model is approximately a 6.3 GB download and needs roughly 6 GB of
VRAM plus runtime overhead at a 4096-token context. Smaller GPUs may split work
between CPU and GPU.

Test the same completion endpoint Minuet uses. This also loads the model:

```bash
curl http://127.0.0.1:11434/v1/completions \
  -H 'Authorization: Bearer ollama' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder:7b-base-q6_K",
    "prompt": "local function add(a, b)\n  return",
    "suffix": "\nend",
    "stream": false,
    "max_tokens": 32,
    "temperature": 0
  }'
```

`Bearer ollama` is a compatibility placeholder for the OpenAI-shaped endpoint;
it is not an authentication secret. Ollama's local API has no application-level
authentication, so keep it on loopback and treat Tailscale access control as the
security boundary.

Verify that the loaded model is fully on the GPU:

```bash
ollama ps
```

The `PROCESSOR` column should report `100% GPU`. For more detail, look for a
Vulkan compute device and fully offloaded layers:

```bash
journalctl -u ollama.service -b --no-pager |
  grep -E 'library=Vulkan|offloaded [0-9]+/[0-9]+ layers'
```

Because Minuet currently has a short request timeout, keeping the model loaded
avoids completion requests timing out during a cold model load. To release its
VRAM manually:

```bash
ollama stop qwen2.5-coder:7b-base-q6_K
```

## Private access through Tailscale

Install and join Tailscale on the Ollama host if it is not already configured:

```bash
sudo pacman -S --needed tailscale
sudo systemctl enable --now tailscaled.service
sudo tailscale up
```

Both the Ollama host and client must be connected to the same tailnet. MagicDNS
and HTTPS certificates must be enabled for the tailnet. Expose the loopback
Ollama service privately and keep the proxy across reboots:

```bash
sudo tailscale serve --bg 11434
tailscale serve status
```

The status output provides an HTTPS URL such as:

```text
https://workstation.example.ts.net
```

Test it manually from a device in the same tailnet:

```bash
curl https://workstation.example.ts.net/api/tags \
  -H 'Host: localhost:11434'
```

Ollama validates the upstream `Host` header when bound to loopback. OrbitVim
automatically applies this header rewrite for `https://*.ts.net` completion
endpoints; manual curl requests need the header shown above.

In Neovim, select the URL without adding a port:

```vim
:MinuetEndpoint https://workstation.example.ts.net
```

Tailscale Serve terminates HTTPS and proxies to
`http://127.0.0.1:11434`. Do not configure Tailscale Funnel for Ollama, and
restrict access using Tailscale grants or ACLs when the tailnet is shared. See
the [Tailscale Serve
documentation](https://tailscale.com/docs/features/tailscale-serve) for HTTPS
and access-control prerequisites.

## Troubleshooting

Useful diagnostics:

```bash
systemctl status ollama.service tailscaled.service
journalctl -u ollama.service -f
tailscale status
tailscale serve status
ollama ps
```

| Symptom | Check |
| --- | --- |
| `Connection refused` on a Tailscale IP at port 11434 | This is expected while Ollama remains loopback-only; use the HTTPS Tailscale Serve URL. |
| MagicDNS returns an empty `403` | The upstream Host header was rejected; OrbitVim handles it automatically, while curl needs `-H 'Host: localhost:11434'`. |
| `ollama ps` reports CPU | Check `vulkaninfo`, `GGML_VK_VISIBLE_DEVICES`, render-device permissions, and the service journal. |
| The first completion times out | Preload the model and use `OLLAMA_KEEP_ALIVE=-1`. |
| Tailscale URL is unavailable after setup | Confirm MagicDNS, HTTPS, Serve status, and tailnet access-control rules. |
