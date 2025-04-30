
## 📘 README: NduguLingo Protocol

---

### 🌍 NduguLingo Protocol - Ancestral Language Preservation on the Blockchain

**Clarity Smart Contract for the Stacks Blockchain**

---

### 🔥 Overview

**NduguLingo Protocol** is a decentralized smart contract system for preserving and revitalizing endangered ancestral languages. It facilitates transparent patronage, registers verified preservation centers, and ensures secure, equitable allocation of resources to documentation projects.

This protocol embodies the spirit of cultural resilience, supporting African and global communities working to protect linguistic heritage for future generations.

---

### 💡 Features

- 📥 **Secure Patronage Contributions**  
  Accepts STX from supporters, records contributions, and routes them to eligible preservation centers.

- 🏛️ **Center Registration and Management**  
  Head Linguist can register centers, track their documentation status, and allocate preservation resources transparently.

- 🔐 **Governance Controls**  
  Manage the program’s operational status, set minimum patronage thresholds, and designate new leadership.

- 🎯 **Priority Mode**  
  Activate emergency allocation mode for high-urgency preservation efforts.

- 📖 **Status Tracking**  
  Track preservation center statuses: `documented`, `in-progress`, `endangered`, or `stable`.

---

### 🛠 Contract Structure

| Component                  | Description |
|---------------------------|-------------|
| `head-linguist`           | Main governance authority |
| `preservation-centers`    | Map of registered documentation centers |
| `patron-registry`         | Ledger of patron contributions |
| `preservation-fund`       | Pool of contributed STX for distribution |
| `priority-mode-active`    | Overrides standard fund allocation logic |

---

### 🔐 Roles

- **Head Linguist:**  
  Authorized to register centers, allocate resources, set policies, and appoint successors.

- **Patrons:**  
  Supporters of the cause who contribute STX and receive recognition via on-chain registry.

---

### 🚀 Functions

#### ✅ Public Calls

- `support-language-preservation`  
  → Contribute STX to the fund.

- `register-preservation-center`  
  → Add a new documentation center.

- `allocate-resources`  
  → Transfer STX to a verified center.

- `update-documentation-status`  
  → Change the documentation progress label.

- `toggle-program-status`  
  → Pause/resume the program.

- `set-priority-mode-on/off`  
  → Enable/disable emergency fund routing.

- `change-head-linguist`  
  → Appoint a new governance authority.

---

### 📎 Read-only Functions

- `get-head-linguist`  
- `get-center-info`  
- `get-patron-info`  
- `get-preservation-fund`  
- `check-program-status`
