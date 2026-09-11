---
marp: true
theme: default
size: 4K
auto-scaling: true
paginate: true
style: |
  section.columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }
  section.topic {
    display: flex;
    align-items: center;
    justify-content: center;

    background: #f8f8f8;
    color: #222;

    font-size: 2.8rem;
    font-weight: 600;
    letter-spacing: -0.03em;
    text-align: center;

    border-left: 0.3rem solid #555;
  }
---

# Practical Transport Layer Security TLS/SSL
## Ilmar Kerm
### 2026

---

# Whoami: Ilmar Kerm

Database administrator at FDJ United
Oracle Ace Associate (ex-Pro)
Member of Symposium 42
Blog: https://ilmarkerm.eu
Bluesky: @ilmarkerm.eu

---

# SSL vs TLS

- SSL -Secure Sockets Layer
- TLS - Transport Layer Security

---

# SSL vs TLS

- Netscape started to develop SSL in 1994
- SSL v3.0 (1996) was widely adopted
- IETF took over the standardisation of the protocol and published TLS 1.0 in 1999.
  - SSL is now deprecated.
- TLS 1.3 is the current standard. TLS 1.2 is also supported.
- TLS 1.1 and 1.0 are deprecated.

---

# The problem

We want to enable end-to-end secure communication for our application
Securing data in transit

---

# TLS

Works directly on TCP
Can secure any TCP based protocol
Provides:
- Confidentiality
- Integrity
- Authenticity

---

# Authenticity

Need to make sure that every party is who they say they are
Avoid man-in-the-middle attacks
Requires PKI and signed certificates
- Each communicating party needs to know each others public keys

---

# Certificates

Public key signed by an Certification Authority
- or by itself - self signed
Avoid self-signed certificates for real use
- Hard to issue new certs, revoke existing ones

---

# Creating a certificate process

copy image

---

# Validity concerns

Use as short certificates as possible.
Revocations are annoying.

---

Oracle uses separate port for TLS secured traffic, for example 1522

PostgreSQL uses StartTLS that start with plain text, but switches to TLS on request - can accommodate plain text and TLS on same port

---

Oracle Native Encryption is no longer

Mainly because TLS 1.3 is faster

---

Vault has strong authentication mechanisms, like OIDC

---

When using user certificates it is possible to force Vault authenticated username to certificate.

---

What information is present in a certificate



---

Revocations

Why short validity is better than dealing with recovations

---

In postgres sslmode must at least be require to avoid falling back to plain text

PostgreSQL sslmode values
disable
prefer
require
validate-full

---

Common errors

hostname mismatch
chain validation errors

10-SEP-2026 17:25:19:778 * (ADDRESS=(PROTOCOL=tcps)(HOST=172.19.0.5)(PORT=48784)) * <unknown connect data> * 29024
ORA-29024: Certificate validation failure
 TNS-00542: SSL Handshake failed

---

postgres username must match certificate CN

---

# Renewals

Generate new certificate, and...

* In Postgres just send SIGHUP signal to postmaster
* If you use Patroni, send SIGHUP to Patroni process instead
* In Oracle, restart listener

---

![bg contain](img/qr-code.svg)
