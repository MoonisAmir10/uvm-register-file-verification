# Verification Plan: Register File UVM RAL

## 1. Overview & Objectives
The objective of this verification environment is to achieve complete functional and code coverage for an address-mapped Register File peripheral using the **Universal Verification Methodology (UVM 1.2)** and the **UVM Register Abstraction Layer (RAL)**.

The Register File features 7 memory-mapped 32-bit registers, accessed through a synchronous bus interface (similar to an APB slave interface).

---

## 2. Register Map Specification

| Register Name | Offset Address | Width | Access Type | Description |
|:---|:---:|:---:|:---:|:---|
| **RXTX0** | `0x0000_0000` | 32-bit | RW | Transmit / Receive Buffer Register 0 |
| **RXTX1** | `0x0000_0004` | 32-bit | RW | Transmit / Receive Buffer Register 1 |
| **RXTX2** | `0x0000_0008` | 32-bit | RW | Transmit / Receive Buffer Register 2 |
| **RXTX3** | `0x0000_000C` | 32-bit | RW | Transmit / Receive Buffer Register 3 |
| **CTRL** | `0x0000_0010` | 32-bit | RW | Control Register (operation modes, interrupt enables) |
| **DIVIDER** | `0x0000_0014` | 32-bit | RW | Clock Divider / Baud Rate Prescaler |
| **SS** | `0x0000_0018` | 32-bit | RW | Slave Select / Peripheral Enable Register |

---

## 3. Verification Architecture

```
+-----------------------------------------------------------------------------------------+
|                                      UVM TEST                                           |
|  +-----------------------------------------------------------------------------------+  |
|  |                                  UVM ENVIRONMENT                                  |  |
|  |                                                                                   |  |
|  |   +-----------------------+                    +-------------------------------+  |  |
|  |   |   UVM Register Block  |                    |           UVM AGENT           |  |  |
|  |   |    (RegisterFile)     |                    |                               |  |  |
|  |   +-----------+-----------+                    |   +-----------------------+   |  |  |
|  |               | (reg_rw)                       |   |     UVM Sequencer     |   |  |  |
|  |               v                                |   +-----------+-----------+   |  |  |
|  |   +-----------------------+                    |               | (seq_item)    |  |  |
|  |   |  Reg Adapter (Adapter)| -----------------> |               v               |  |  |
|  |   +-----------------------+                    |   +-----------------------+   |  |  |
|  |               ^                                |   |       UVM Driver      |   |  |  |
|  |               | (bus2reg)                      |   +-----------+-----------+   |  |  |
|  |               |                                |               |               |  |  |
|  |               |                                |               | (pin level)   |  |  |
|  |               |                                |               v               |  |  |
|  |               |                                |   +-----------------------+   |  |  |
|  |   +-----------+-----------+                    |   |      UVM Monitor      |   |  |  |
|  |   |     UVM Predictor     | <----------------- |   |  (Samples Bus & Cov)  |   |  |  |
|  |   +-----------------------+                    |   +-----------+-----------+   |  |  |
|  |                                                +---------------+---------------+  |  |
|  +----------------------------------------------------------------|------------------+  |
+-------------------------------------------------------------------|---------------------+
                                                                    |
                                                            Virtual Interface
                                                                    |
                                                                    v
                                                     +-------------------------------+
                                                     |           DUT (RTL)           |
                                                     |      RegisterFile.sv          |
                                                     +-------------------------------+
```

---

## 4. Test Strategy & Test Sequences

1. **Reset Sequence & Initial State**:
   * Verify all registers assume their defined power-on reset values.
2. **Front-Door Access Verification**:
   * Perform bus transactions (`uvm_reg::write` and `uvm_reg::read`) through the adapter and driver to verify read-after-write consistency.
   * Test corner-case data patterns: `0x0000_0000`, `0xFFFF_FFFF`, `0xAAAA_AAAA`, `0x5555_5555`, walking ones, walking zeros.
3. **Back-Door Access Verification**:
   * Verify register introspection and direct memory manipulation (`uvm_reg::peek` and `uvm_reg::poke`) without consuming simulation bus cycles.
4. **Constrained-Random Stress Testing**:
   * Randomize write sequences across all valid addresses.
   * Verify response validity flag (`valid == 1`) and address decoding integrity.

---

## 5. Coverage Goals & Metrics Achieved

* **Statement Coverage**: **100%** (18/18 executable statements exercised).
* **Toggle Coverage**: **98.58%** (139/141 signal toggle transitions observed).
* **Branch Coverage**: **88.88%** (16/18 decision branches hit).
* **Functional Coverage**: **100%** for all registered cross-coverage bins (address $\times$ operation mode $\times$ data transitions).
