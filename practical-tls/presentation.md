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

---

# Whoami: Ilmar Kerm

Database administrator at FDJ United
Oracle Ace Associate (ex-Pro)
Member of Symposium 42
Blog: https://ilmarkerm.eu,
@ilmarkerm.eu

---

Oracle Native Encryption is no longer

Mainly because TLS 1.3 is faster

---

Vault has strong authentication mechanisms, like OIDC

---

When using user certificates it is possible to force Vault authenticated username to certificate.

---

In postgres sslmode must at least be require to avoid falling back to plain text

---

Common errors

hostname mismatch
chain validation errors

---

postgres username must match certificate CN
