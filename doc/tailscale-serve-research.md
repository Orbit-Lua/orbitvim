# Tailscale Serve for a Loopback Ollama Backend

Research date: 2026-08-17

Scope: validate the current Tailscale Serve syntax and security properties for
proxying `http://127.0.0.1:11434` to private Tailscale clients. Only Tailscale
first-party documentation and source code were used.

## Conclusions

Both requested commands are valid, but the protocol before the backend and the
protocol exposed to clients are separate choices:

| Client-facing listener | Command | Client URL shape |
| --- | --- | --- |
| HTTP on port 11434 | `tailscale serve --bg --http=11434 http://127.0.0.1:11434` | `http://<machine-name>:11434` |
| HTTPS on the default port 443 | `tailscale serve --bg http://127.0.0.1:11434` | `https://<machine-name>.<tailnet-name>.ts.net` |

The explicit target URL always describes the local upstream. It does not select
the client-facing protocol. `--http=11434` selects an HTTP listener on port
11434. With no listener flag, Serve defaults to HTTPS on port 443. The current
CLI reference documents full HTTP URLs as valid reverse-proxy targets and both
`--http=<port>` and default HTTPS; the implementation independently confirms
the flags, target expansion, and default.

Sources:

- [Serve CLI: flags, proxy targets, and HTTP/HTTPS behavior](https://tailscale.com/docs/reference/tailscale-cli/serve#use-https-and-http-servers)
- [CLI source: `--http`, `--https`, and `--bg` flags](https://github.com/tailscale/tailscale/blob/cfe32b8be6a33f8e24fbc369cbfbf7c729d9e042/cmd/tailscale/cli/serve_v2.go#L239-L250)
- [CLI source: HTTP is the default upstream scheme for proxy targets](https://github.com/tailscale/tailscale/blob/cfe32b8be6a33f8e24fbc369cbfbf7c729d9e042/cmd/tailscale/cli/serve_v2.go#L1273-L1281)
- [CLI source: no listener flag defaults to HTTPS port 443](https://github.com/tailscale/tailscale/blob/cfe32b8be6a33f8e24fbc369cbfbf7c729d9e042/cmd/tailscale/cli/serve_v2.go#L1396-L1429)

Run `tailscale serve status` after either command and use the URL it reports.
This avoids assuming a machine or tailnet DNS name.

## HTTP mode without a TLS certificate

The HTTP form is the appropriate alternative when the tailnet HTTPS certificate
feature cannot or should not be enabled. It creates a plain HTTP origin from the
application's perspective, but traffic between Tailscale nodes still traverses
Tailscale's WireGuard-encrypted data plane. Tailscale states that direct, DERP,
and peer-relay connections are all end-to-end encrypted; the connection type
changes performance, not this protection.

The security boundary should be described precisely:

- The client-to-Serve-node network path remains encrypted and authenticated by
  Tailscale even when the URL begins with `http://`.
- There is no additional TLS layer or public-CA certificate at the HTTP layer.
  Browsers and API clients can therefore label the origin insecure or reject
  features that require a secure HTTPS context.
- The Serve node forwards to `127.0.0.1:11434` locally. Keeping Ollama on
  loopback avoids exposing its unauthenticated API directly to the LAN or
  tailnet.
- This reasoning applies only while clients reach the HTTP listener over their
  Tailscale connection. It must not be generalized to ordinary LAN or public
  HTTP exposure.

Tailscale's HTTPS guide explicitly distinguishes these layers: Tailscale-node
connections are end-to-end encrypted, while applications still recognize an
HTTP URL as lacking TLS. The Serve guide also recommends keeping proxied
backends on localhost so clients cannot bypass Serve and spoof its identity
headers.

Sources:

- [Tailscale encryption: all connection types use end-to-end WireGuard encryption](https://tailscale.com/docs/reference/connection-types)
- [HTTPS guide: Tailscale encryption does not make an HTTP URL an HTTPS origin](https://tailscale.com/docs/how-to/set-up-https-certificates)
- [Serve security guidance: keep a proxied backend on localhost](https://tailscale.com/docs/features/tailscale-serve#identity-headers)

### Documentation discrepancy

The high-level Serve page says that Serve requires HTTPS certificates. The
newer CLI reference nevertheless documents HTTP listeners, and the current CLI
implementation starts the HTTPS enablement flow only when the selected listener
type is HTTPS. It does not run that flow for `--http`.

For this guide, describe HTTPS enablement as a prerequisite for the HTTPS
variant, not for the explicit HTTP variant. This matches the more specific CLI
reference and current implementation.

Sources:

- [High-level Serve setup wording](https://tailscale.com/docs/features/tailscale-serve#get-started-with-serve)
- [CLI source: HTTPS enablement is conditional on an HTTPS listener](https://github.com/tailscale/tailscale/blob/cfe32b8be6a33f8e24fbc369cbfbf7c729d9e042/cmd/tailscale/cli/serve_v2.go#L462-L475)

## HTTPS prerequisites and certificate handling

For the default HTTPS command:

1. Enable MagicDNS on the tailnet's DNS admin page.
2. Enable HTTPS certificates and accept the Certificate Transparency
   disclosure.
3. Run the Serve command. If the prerequisite is missing, the interactive CLI
   provides a consent URL; Serve automatically obtains and uses the certificate
   and `tailscaled` terminates TLS.

The guide should say that the *tailnet HTTPS certificate feature* must be
enabled. It should not imply that the user must manually install a certificate
file before running Serve. Manual `tailscale cert` handling is a separate use
case; Serve automatically provisions its listener certificate.

HTTPS certificates use the fully qualified MagicDNS name, such as
`workstation.example.ts.net`. A bare hostname such as
`https://workstation` cannot have the Tailscale-issued certificate. Enabling
HTTPS also publishes the certificate's device and tailnet DNS name in public
Certificate Transparency logs, even though the service remains private. Rename
machines that contain sensitive information before enabling the feature.

Sources:

- [Serve automatically provisions TLS and terminates HTTPS](https://tailscale.com/docs/reference/tailscale-cli/serve#use-https-and-http-servers)
- [Serve HTTPS prerequisite and interactive enablement](https://tailscale.com/docs/features/tailscale-serve#get-started-with-serve)
- [Enable HTTPS: MagicDNS, HTTPS, FQDN, and Certificate Transparency](https://tailscale.com/docs/how-to/set-up-https-certificates#configure-https)

## MagicDNS and tailnet access

HTTP servers can be reached using a short MagicDNS hostname, with the configured
non-default port in this case: `http://workstation:11434`. MagicDNS expands the
machine name using the tailnet search domain. Fully qualified MagicDNS names
remain available and are required for HTTPS certificate validation.

Serve is private to Tailscale connectivity; Funnel is the separate feature for
public internet exposure. Access-control grants or ACLs apply to Serve like any
other tailnet service. Being connected to Tailscale must not be presented as
application authorization: a new/default tailnet policy can allow broad access,
so the Ollama port should be limited to the intended users or devices.

Sources:

- [Serve CLI: HTTP listeners use short MagicDNS names](https://tailscale.com/docs/reference/tailscale-cli/serve#use-https-and-http-servers)
- [MagicDNS: machine names, FQDNs, and search domains](https://tailscale.com/docs/features/magicdns#fully-qualified-domain-names-vs-machine-names)
- [Serve is tailnet-only and access controls apply](https://tailscale.com/docs/features/tailscale-serve)
- [ACL behavior and the default allow-all policy](https://tailscale.com/docs/features/access-control/acls)

Do not recommend Funnel for Ollama. The same port cannot simultaneously be
private Serve and public Funnel; the most recent configuration determines
whether that port is private or public.

Source: [Serve limitations for ports shared with Funnel](https://tailscale.com/docs/features/tailscale-serve#limitations)

## Background persistence and operations

`--bg` stores the Serve configuration and keeps it active after the invoking
terminal exits. It automatically resumes after a device reboot and after
`tailscale down` followed by `tailscale up`, and remains active until explicitly
disabled. Without `--bg`, the process is foreground-only and must be restarted
after these events.

Useful operations for the guide:

```bash
tailscale serve status
tailscale serve --http=11434 off
tailscale serve reset
```

The first command inspects the active URL and proxy mapping. The second removes
the custom HTTP listener; the target argument may be omitted for an `off`
command. `reset` clears the complete Serve configuration, so it should be
described as broader than disabling this single listener.

Sources:

- [`--bg` persistence across reboot and Tailscale restart](https://tailscale.com/docs/reference/tailscale-cli/serve#effects-of-rebooting-and-restarting)
- [Status, per-listener disablement, and reset](https://tailscale.com/docs/reference/tailscale-cli/serve#get-the-status)

## Recommended wording for the Ollama guide

- Call the two modes "client-facing HTTP" and "client-facing HTTPS". Both proxy
  the same local HTTP upstream.
- Prefer HTTPS when the tailnet HTTPS feature is available and publishing the
  machine's FQDN in Certificate Transparency is acceptable.
- Present HTTP as a valid private-tailnet fallback. Explain that WireGuard still
  protects the Tailscale path, while HTTP lacks application-layer TLS and a
  browser-recognized secure origin.
- Keep `OLLAMA_HOST` on `127.0.0.1:11434`, use Serve rather than Funnel, and
  restrict port 11434 or 443 with grants or ACLs.
- Tell readers to copy the endpoint from `tailscale serve status` instead of
  constructing a hostname from examples.
