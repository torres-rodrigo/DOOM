\# GOPASS

Nice — I like your constraints (no third-party SaaS, Linux-first, self-hostable). Below is a practical, modern, \*\*self-hostable password \& secret management workflow\*\* built for a Linux power-user: recommended tools, security rationale (with sources), and a step-by-step \_how to\_ you can follow now on multiple devices. I include exact commands and a short onboarding checklist you can copy-paste.



---



\## 1) Short summary / recommendations (quick pick)



\- \*\*Primary CLI password store (recommended):\*\* \*\*gopass\*\* (the actively-maintained successor to `pass`) — stores entries as files, encrypts per-file, integrates with Git, supports `age` or GPG backends. (\[GitHub](https://github.com/gopasspw/gopass?utm\_source=chatgpt.com "The slightly more awesome standard UNIX password manager for ... - GitHub"))

&nbsp;   

\- \*\*Modern file encryption backend:\*\* \*\*age\*\* — simple, modern, secure, post-quantum ready recipients. Use with gopass or for encrypting individual files. (\[GitHub](https://github.com/FiloSottile/age?utm\_source=chatgpt.com "GitHub - FiloSottile/age: A simple, modern and secure encryption tool ..."))

&nbsp;   

\- \*\*Optional GUI / multi-user self-hosted server:\*\* \*\*Vaultwarden\*\* (lightweight Bitwarden API server) if you want web/phone clients but still self-hosted. (\[GitHub](https://github.com/dani-garcia/vaultwarden?utm\_source=chatgpt.com "GitHub - dani-garcia/vaultwarden: Unofficial Bitwarden compatible ..."))

&nbsp;   

\- \*\*Secrets-as-code (repo) tool:\*\* \*\*sops\*\* for encrypting structured secrets in Git, supports `age`. (\[GitHub](https://github.com/getsops/sops?utm\_source=chatgpt.com "GitHub - getsops/sops: Simple and flexible tool for managing secrets"))

&nbsp;   

\- \*\*Hardware 2FA / private key protection:\*\* \*\*YubiKey\*\* (use it as a smartcard for GPG/SSH keys) — strongly recommended for protecting private keys. (\[GitHub](https://github.com/drduh/YubiKey-Guide?utm\_source=chatgpt.com "GitHub - drduh/YubiKey-Guide: Community guide to using YubiKey for ..."))

&nbsp;   

\- \*\*GUI local vault (optional):\*\* \*\*KeePassXC\*\* + Syncthing/WebDAV for sync if you prefer a single database file and cross-platform GUI. (\[keepassxc.org](https://keepassxc.org/docs/?utm\_source=chatgpt.com "Documentation and FAQ – KeePassXC"))

&nbsp;   



Below I explain why these choices match your requirements and give a reproducible workflow.



---



\## 2) Why these choices (security rationale, short)



\- \*\*gopass / pass model\*\*: file per secret + Git revisioning gives you auditability and easy multi-device sync (use your own git remote or Syncthing). gopass adds convenience and extra features over pass. (\[GitHub](https://github.com/gopasspw/gopass?utm\_source=chatgpt.com "The slightly more awesome standard UNIX password manager for ... - GitHub"))

&nbsp;   

\- \*\*age vs GPG\*\*: `age` is intentionally simple, fewer footguns, modern defaults, and now widespread (and supported by gopass/sops). Use age for new setups; GPG + YubiKey is still excellent when you want the smartcard properties. (\[GitHub](https://github.com/FiloSottile/age?utm\_source=chatgpt.com "GitHub - FiloSottile/age: A simple, modern and secure encryption tool ..."))

&nbsp;   

\- \*\*Argon2 for passphrase hashing / PBKDF:\*\* when you pick passphrases (or configure tools that derive keys from passphrases), prefer Argon2id per OWASP / RFC recommendations. (This matters for service-side hashing, but also guides how strong your master passphrase should be.) (\[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/Password\_Storage\_Cheat\_Sheet.html?utm\_source=chatgpt.com "Password Storage - OWASP Cheat Sheet Series"))

&nbsp;   

\- \*\*Hardware tokens\*\*: Put a copy of your primary signing/auth keys on a YubiKey (non-exportable) so a stolen laptop doesn't mean immediate key theft. (\[GitHub](https://github.com/drduh/YubiKey-Guide?utm\_source=chatgpt.com "GitHub - drduh/YubiKey-Guide: Community guide to using YubiKey for ..."))

&nbsp;   



---



\## 3) Practical workflow — single-user, self-hosted, Linux-first



I’ll show a recommended \*\*gopass + age + Git\*\* workflow (CLI oriented), plus notes for YubiKey, sops for repo secrets, and alternatives.



> Assumptions: you have `git`, `curl`, `ssh`, `age`, and `gopass` available or installable on your Linux machines.



\## A. Install core tools (Debian/Ubuntu example)



```bash

\# gopass (from upstream repo or package)

sudo apt update

sudo apt install -y git age



\# install gopass

\# on many distros: `sudo apt install gopass` or use install script / package from https://www.gopass.pw

\# Example (recommended: use your distro package or release binary):

curl -sSfL https://raw.githubusercontent.com/gopasspw/gopass/main/install.sh | bash



\# install sops (for repo secrets)

sudo apt install -y sops  # or follow get.sops.dev install instructions



\# optionally install KeePassXC for GUI

sudo apt install -y keepassxc

```



(If your distro doesn’t have latest gopass/age, use their GitHub releases pages.) (\[gopass.pw](https://www.gopass.pw/?utm\_source=chatgpt.com "gopass - The Password Manager for Developers"))



\## B. Generate an `age` keypair (on your primary device)



```bash

\# generate a file key (keep private safe)

age-keygen -o ~/.config/age/keys.txt

\# public recipient

grep public ~/.config/age/keys.txt    # shows the `age1...` recipient string

```



Store the private `keys.txt` safely (more on backups below). (\[Go Packages](https://pkg.go.dev/filippo.io/age?utm\_source=chatgpt.com "age package - filippo.io/age - Go Packages"))



\## C. Initialize a gopass store using age



```bash

\# make an empty git repo on your self-hosted server (or use a private git hosting you control)

\# example: create repo on your server at git@yourserver:/srv/pass-repo.git



\# init gopass with age recipient:

gopass init --crypto age "age1..."   # use the public recipient string from the age key

\# gopass will initialize a git repo under ~/.password-store

```



You can push this repo to your \*\*own\*\* Git server (self-hosted Git: gitea, gitolite, bare repo on VPS) or use Syncthing instead of Git if you prefer P2P sync. gopass supports pushing to a remote git. (\[GitHub](https://github.com/gopasspw/gopass?utm\_source=chatgpt.com "The slightly more awesome standard UNIX password manager for ... - GitHub"))



\## D. Add secrets (examples)



```bash

\# add a web login

gopass insert personal/email@gmail.com

\# follow prompts for username and password



\# add an SSH private key (encrypt and remove plain file)

gopass insert --multiline ssh/id\_ed25519 <<'EOF'

-----BEGIN OPENSSH PRIVATE KEY-----

...

-----END OPENSSH PRIVATE KEY-----

EOF



\# or encrypt an existing key with age directly

age -r age1... -o id\_ed25519.age ~/.ssh/id\_ed25519

shred -u ~/.ssh/id\_ed25519       # remove plaintext after encryption (careful)

gopass insert --multiline ssh/id\_ed25519 < id\_ed25519.age

```



\*\*Note:\*\* Never keep unencrypted private keys in plain filesystem backups. Use `shred -u` (or `srm`) to securely delete plaintext after encrypting. (See device onboarding below.) (\[GitHub](https://github.com/gopasspw/gopass?utm\_source=chatgpt.com "The slightly more awesome standard UNIX password manager for ... - GitHub"))



\## E. Syncing between devices (options)



Pick one of the two patterns below:



\*\*Option 1 — Git remote (my preferred for power users)\*\*



\- Create a bare git repo on a server you control (SSH access only). Push `~/.password-store` to it. On other devices `gopass clone git@yourserver:/srv/pass-repo.git`.

&nbsp;   

\- Make sure the `age` private key (or GPG smartcard) is available on each device (see onboarding). Use `gopass recipients` to list who can decrypt.

&nbsp;   



\*\*Option 2 — Syncthing (no central server)\*\*



\- Use Syncthing to replicate `~/.password-store` across devices. Keep it encrypted with `age` so raw files remain safe even if Syncthing sync target is compromised. (Syncthing handles transport, gopass/age handles encryption.)

&nbsp;   



Either way: \*\*do not store the age private key on the same host unencrypted\*\*, and follow the backup procedure below. gopass + git gives you history and easy rollbacks. (\[gopass.pw](https://www.gopass.pw/?utm\_source=chatgpt.com "gopass - The Password Manager for Developers"))



---



\## 4) Onboarding a new machine (step-by-step)



1\. Install `gopass`, `age`, `git`.

&nbsp;   

2\. Get the repo (git clone or gopass clone) or configure Syncthing sync.

&nbsp;   

&nbsp;   ```bash

&nbsp;   # clone gopass store:

&nbsp;   gopass clone git@yourserver:/srv/pass-repo.git

&nbsp;   ```

&nbsp;   

3\. Add your \*\*age private key\*\* to the new device (securely transfer — see recommended methods):

&nbsp;   

&nbsp;   - Best: export the `age` private key onto an encrypted USB that you carry (LUKS encrypted) and import locally; or use a YubiKey or smartcard.

&nbsp;       

&nbsp;   - If you must copy over SSH, use an existing trusted machine -> `scp` directly and remove source copy only after verification.

&nbsp;       

4\. Verify you can decrypt an entry: `gopass show personal/email@gmail.com`.

&nbsp;   

5\. Optionally set up gopass extensions (browser integration) or CLI convenience.

&nbsp;   



\*\*On transfer security:\*\* copy `~/.config/age/keys.txt` only from a trusted, uncompromised source — avoid emailing or cloud copying. If you ever suspect the private key was copied insecurely, rotate: make a new age keypair and add the new recipient to gopass (`gopass recipients add <new-recipient>`, then `gopass reencrypt --all`) and remove the old recipient. (\[Go Packages](https://pkg.go.dev/filippo.io/age?utm\_source=chatgpt.com "age package - filippo.io/age - Go Packages"))



---



\## 5) Protecting SSH keys — recommended patterns



\- \*\*Prefer Ed25519\*\* keys for user SSH keys. They are smaller, fast, and the current recommended choice. Generate with:

&nbsp;   

&nbsp;   ```bash

&nbsp;   ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id\_ed25519 -C "your@host"

&nbsp;   ```

&nbsp;   

&nbsp;   `-a 100` increases KDF rounds for the private key passphrase (OpenSSH uses bcrypt KDF for PEM keys). Ed25519 is generally recommended for new keys. (\[Linux Audit](https://linux-audit.com/ssh/using-ed25519-openssh-keys-instead-of-dsa-rsa-ecdsa/?utm\_source=chatgpt.com "Using Ed25519 for OpenSSH keys (instead of DSA/RSA/ECDSA)"))

&nbsp;   

\- \*\*Keep private SSH key encrypted at rest\*\* and only decrypt in memory with `ssh-agent` or `gpg-agent`. Do not copy plaintext private keys between machines. Store the encrypted version in gopass and decrypt when you need it:

&nbsp;   

&nbsp;   ```bash

&nbsp;   gopass show --clip ssh/id\_ed25519    # copies to clipboard temporarily (gopass handles expiry)

&nbsp;   ```

&nbsp;   

\- \*\*Hardware option:\*\* put your SSH key on a YubiKey (or use the YubiKey OpenPGP app + SSH from GPG agent). This makes the private key non-exportable. See YubiKey guides for details. (\[GitHub](https://github.com/drduh/YubiKey-Guide?utm\_source=chatgpt.com "GitHub - drduh/YubiKey-Guide: Community guide to using YubiKey for ..."))

&nbsp;   



---



\## 6) Backup \& recovery (critical)



\- \*\*Back up your age private key\*\* \_off-site\_ (encrypted) and \*\*offline\*\* (e.g., LUKS-encrypted USB drive kept in a secure location). Keep at least \*\*two\*\* copies in separate locations (e.g., safe, safety deposit box).

&nbsp;   

\- \*\*Emergency kit\*\* (store in a sealed envelope and safe place) should include:

&nbsp;   

&nbsp;   - Your age private key file (encrypted with passphrase or stored on a hardware token).

&nbsp;       

&nbsp;   - Short recovery instructions and the Git remote URL for the password store.

&nbsp;       

&nbsp;   - A printed copy (no passwords — just instructions and public recipient ID).

&nbsp;       

\- \*\*Rotate keys\*\* if a device is lost or you suspect compromise: create new age keypair, add new recipient to the store, `gopass reencrypt --all`, and remove old recipients. Push to remote and confirm other devices update. (\[Go Packages](https://pkg.go.dev/filippo.io/age?utm\_source=chatgpt.com "age package - filippo.io/age - Go Packages"))

&nbsp;   



---



\## 7) Integrating with code/config (secrets as code)



\- Use \*\*sops\*\* to encrypt YAML/JSON/ENV files using `age` recipients. This lets you keep encrypted config in GitOps repos and decrypt locally or in CI with the private key. Example:

&nbsp;   

&nbsp;   ```bash

&nbsp;   # encrypt file

&nbsp;   sops --encrypt --age age1... secrets.yaml > secrets.yaml.enc

&nbsp;   # decrypt

&nbsp;   sops --decrypt secrets.yaml.enc > secrets.yaml

&nbsp;   ```

&nbsp;   



sops works well with `age` and is a standard for GitOps workflows. (\[GitHub](https://github.com/getsops/sops?utm\_source=chatgpt.com "GitHub - getsops/sops: Simple and flexible tool for managing secrets"))



---



\## 8) Optional: if you want GUI + phone clients



\- \*\*Vaultwarden\*\* (self-hosted) gives you Bitwarden-compatible clients (mobile/desktop/web) while staying on your hardware. Great if you need shared vaults or browser autofill. Host in Docker on your VPS. If you want \_no server at all\_, skip this and stick to gopass + browser extensions (gopass has browser integration). (\[GitHub](https://github.com/dani-garcia/vaultwarden?utm\_source=chatgpt.com "GitHub - dani-garcia/vaultwarden: Unofficial Bitwarden compatible ..."))

&nbsp;   

\- \*\*KeePassXC + Syncthing\*\* is an alternative if you prefer a single database file and GUI apps across desktop and phone (use KeePassXC on Linux desktops and Keepass2Android on phones). Syncthing syncs the DB file between devices; DB is encrypted with AES and passphrase. (\[keepassxc.org](https://keepassxc.org/docs/?utm\_source=chatgpt.com "Documentation and FAQ – KeePassXC"))

&nbsp;   



---



\## 9) Recommended policies / protocols (write these down and follow them)



\- \*\*Master passphrase:\*\* use a long, unique passphrase (passphrase manager uses Argon2 iterations if applicable). Treat it like the root key to everything. Use a physically stored recovery. (\[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/Password\_Storage\_Cheat\_Sheet.html?utm\_source=chatgpt.com "Password Storage - OWASP Cheat Sheet Series"))

&nbsp;   

\- \*\*Hardware 2FA for keys:\*\* put your critical SSH/GPG signing keys on a YubiKey. Require a physical touch for high-risk operations. (\[GitHub](https://github.com/drduh/YubiKey-Guide?utm\_source=chatgpt.com "GitHub - drduh/YubiKey-Guide: Community guide to using YubiKey for ..."))

&nbsp;   

\- \*\*Device hygiene for onboarding:\*\* only import private key material from a trusted machine or encrypted offline media. After import, verify decryption and then securely erase the transfer medium (if temporary).

&nbsp;   

\- \*\*Rotate on suspicion:\*\* if any device is lost or you worry it’s compromised, rotate keys and reencrypt the store with new recipients ASAP.

&nbsp;   

\- \*\*Minimal exposure:\*\* when using ssh-agent forwarding, only forward to machines you trust and for short sessions. Agent-forwarding can expose keys if the remote host is compromised. (\[Brandon Checketts](https://www.brandonchecketts.com/archives/ssh-ed25519-key-best-practices-for-2025?utm\_source=chatgpt.com "SSH Key Best Practices for 2025 - Using ed25519, key rotation, and ..."))

&nbsp;   



---



\## 10) Quick copy-paste checklist to “get it done” (one primary machine)



1\. Install `git`, `gopass`, `age`, `sops`.

&nbsp;   

2\. `age-keygen -o ~/.config/age/keys.txt` → note public `age1...` recipient.

&nbsp;   

3\. `gopass init --crypto age age1...`

&nbsp;   

4\. Add secrets with `gopass insert site/username` and `gopass insert --multiline ssh/id\_ed25519`.

&nbsp;   

5\. Create bare git repo on your VPS: `git init --bare /srv/pass-repo.git` and `cd ~/.password-store \&\& git remote add origin git@yourserver:/srv/pass-repo.git \&\& git push -u origin master`.

&nbsp;   

6\. On each new device: install tools → `gopass clone git@yourserver:/srv/pass-repo.git` → securely import your `~/.config/age/keys.txt` from encrypted USB.

&nbsp;   

7\. Make two physical backups of the age private key (LUKS USB + safe). Rotate keys if needed.

&nbsp;   



---



\## 11) Helpful references / reading (short)



\- gopass site / docs (gopass + git + age support). (\[gopass.pw](https://www.gopass.pw/?utm\_source=chatgpt.com "gopass - The Password Manager for Developers"))

&nbsp;   

\- age encryption (design + usage). (\[GitHub](https://github.com/FiloSottile/age?utm\_source=chatgpt.com "GitHub - FiloSottile/age: A simple, modern and secure encryption tool ..."))

&nbsp;   

\- Vaultwarden (self-hosted Bitwarden server). (\[GitHub](https://github.com/dani-garcia/vaultwarden?utm\_source=chatgpt.com "GitHub - dani-garcia/vaultwarden: Unofficial Bitwarden compatible ..."))

&nbsp;   

\- sops (encrypt config files in git). (\[GitHub](https://github.com/getsops/sops?utm\_source=chatgpt.com "GitHub - getsops/sops: Simple and flexible tool for managing secrets"))

&nbsp;   

\- YubiKey guide for SSH/GPG operations. (\[GitHub](https://github.com/drduh/YubiKey-Guide?utm\_source=chatgpt.com "GitHub - drduh/YubiKey-Guide: Community guide to using YubiKey for ..."))

&nbsp;   

\- OWASP Password Storage (Argon2 recommendation). (\[OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/cheatsheets/Password\_Storage\_Cheat\_Sheet.html?utm\_source=chatgpt.com "Password Storage - OWASP Cheat Sheet Series"))

&nbsp;   



---



\## 12) Alternatives \& tradeoffs (short)



\- \*\*KeePassXC + Syncthing\*\* — simpler UI, single file DB (easy mobile support), but single DB file is a single point of failure unless backed up properly. (\[keepassxc.org](https://keepassxc.org/docs/?utm\_source=chatgpt.com "Documentation and FAQ – KeePassXC"))

&nbsp;   

\- \*\*Vaultwarden\*\* — great for cross-device browser/mobile integration, but now you run a server with a web UI (slightly larger attack surface). Good if you need mobile apps/autofill. (\[GitHub](https://github.com/dani-garcia/vaultwarden?utm\_source=chatgpt.com "GitHub - dani-garcia/vaultwarden: Unofficial Bitwarden compatible ..."))

&nbsp;   

\- \*\*HashiCorp Vault\*\* — enterprise-grade secrets manager for infrastructure (dynamic secrets, leases). Overkill for personal use but ideal if you later manage infra secrets at scale. (\[HashiCorp Developer](https://developer.hashicorp.com/vault/tutorials/secrets-management?utm\_source=chatgpt.com "Secrets management | Vault | HashiCorp Developer"))

&nbsp;   



---



If you want, I can \*\*do one of the following next (pick one)\*\* and I’ll generate it immediately:



1\. A ready-to-run set of shell commands (script) to bootstrap `gopass + age` on a fresh Linux box (with prompts where human input is required).

&nbsp;   

2\. A short printable \*\*“Emergency kit” document\*\* (one page) you can store physically — includes recovery steps and where to find backups.

&nbsp;   

3\. A walkthrough for setting up \*\*YubiKey with GPG/SSH\*\* on Linux (commands + config).

&nbsp;   



Tell me which of (1)/(2)/(3) you want and I’ll produce it now — no waiting.



\# Alts

