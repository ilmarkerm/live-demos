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

Add some slides what TLS is from the older presentation

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
