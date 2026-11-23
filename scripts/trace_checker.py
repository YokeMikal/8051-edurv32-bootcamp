# -*- coding: utf-8 -*-
"""Golden 8051 ISA reference model vs RTL DUT trace checker (WBS 1.7 / E01-E04 / E08)."""

import argparse
import csv
import os
import sys


def load_rom_in(path):
    mem = [0] * 65536
    addr = 0
    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.split("//", 1)[0].strip()
            if not line:
                continue
            for tok in line.split():
                if tok.startswith("@"):
                    addr = int(tok[1:], 16)
                else:
                    mem[addr] = int(tok, 16) & 0xFF
                    addr += 1
    return mem


def parity8(val):
    return bin(val & 0xFF).count("1") & 1


class Golden8051(object):
    def __init__(self, rom):
        self.rom = rom
        self.pc = 0x0000
        self.acc = 0x00
        self.b = 0x00
        self.psw = 0x00  # [7]=CY, [6]=AC, [5]=F0, [4:3]=RS, [2]=OV, [0]=P
        self.sp = 0x07
        self.ram = [0] * 256
        self.p0 = 0xFF
        self.p1 = 0xFF
        self.p2 = 0xFF
        self.p3 = 0xFF

    def update_p(self):
        self.psw = (self.psw & 0xFE) | parity8(self.acc)

    def read_direct(self, addr):
        a = addr & 0xFF
        if a < 0x80:
            return self.ram[a]
        if a == 0xE0:
            return self.acc
        if a == 0xF0:
            return self.b
        if a == 0xD0:
            return self.psw
        if a == 0x81:
            return self.sp
        if a == 0x80:
            return self.p0
        if a == 0x90:
            return self.p1
        if a == 0xA0:
            return self.p2
        if a == 0xB0:
            return self.p3
        return 0x00

    def write_direct(self, addr, val):
        a = addr & 0xFF
        v = val & 0xFF
        if a < 0x80:
            self.ram[a] = v
        elif a == 0xE0:
            self.acc = v
            self.update_p()
        elif a == 0xF0:
            self.b = v
        elif a == 0xD0:
            self.psw = (v & 0xFE) | parity8(self.acc)
        elif a == 0x81:
            self.sp = v
        elif a == 0x80:
            self.p0 = v
        elif a == 0x90:
            self.p1 = v
        elif a == 0xA0:
            self.p2 = v
        elif a == 0xB0:
            self.p3 = v

    def bank_base(self):
        return ((self.psw >> 3) & 0x03) * 8

    def read_rn(self, n):
        return self.ram[self.bank_base() + n]

    def write_rn(self, n, val):
        self.ram[self.bank_base() + n] = val & 0xFF

    def add_with_carry(self, a, b, cin):
        lo = (a & 0x0F) + (b & 0x0F) + cin
        ac = 1 if lo > 0x0F else 0
        mid = ((a >> 4) & 0x07) + ((b >> 4) & 0x07) + (1 if ((a & 0x7F) + (b & 0x7F) + cin) > 0x7F else 0)
        c6 = 1 if (((a & 0x7F) + (b & 0x7F) + cin) > 0x7F) else 0
        total = a + b + cin
        cy = 1 if total > 0xFF else 0
        ov = cy ^ c6
        res = total & 0xFF
        self.acc = res
        self.psw = (cy << 7) | (ac << 6) | (self.psw & 0x38) | (ov << 2) | (self.psw & 0x02) | parity8(res)

    def subb_with_borrow(self, a, b):
        cin = (self.psw >> 7) & 1
        ac = 1 if (a & 0x0F) < ((b & 0x0F) + cin) else 0
        c6 = 1 if (a & 0x7F) < ((b & 0x7F) + cin) else 0
        diff = a - b - cin
        cy = 1 if diff < 0 else 0
        ov = cy ^ c6
        res = diff & 0xFF
        self.acc = res
        self.psw = (cy << 7) | (ac << 6) | (self.psw & 0x38) | (ov << 2) | (self.psw & 0x02) | parity8(res)

    def step(self):
        pc_now = self.pc
        op = self.rom[pc_now]
        b1 = self.rom[(pc_now + 1) & 0xFFFF]
        b2 = self.rom[(pc_now + 2) & 0xFFFF]
        mnem = "OP_{:02X}".format(op)

        if op == 0x00:  # NOP
            mnem = "NOP"
            self.pc = (pc_now + 1) & 0xFFFF
        elif op == 0x04:  # INC A
            mnem = "INC A"
            self.acc = (self.acc + 1) & 0xFF
            self.update_p()
            self.pc = (pc_now + 1) & 0xFFFF
        elif op == 0x74:  # MOV A, #imm
            mnem = "MOV A,#{:02X}h".format(b1)
            self.acc = b1
            self.update_p()
            self.pc = (pc_now + 2) & 0xFFFF
        elif 0x78 <= op <= 0x7F:  # MOV Rn, #imm
            rn = op - 0x78
            mnem = "MOV R{},#{:02X}h".format(rn, b1)
            self.write_rn(rn, b1)
            self.pc = (pc_now + 2) & 0xFFFF
        elif op == 0x75:  # MOV direct, #imm
            mnem = "MOV {:02X}h,#{:02X}h".format(b1, b2)
            self.write_direct(b1, b2)
            self.pc = (pc_now + 3) & 0xFFFF
        elif op == 0xF5:  # MOV direct, A
            mnem = "MOV {:02X}h,A".format(b1)
            self.write_direct(b1, self.acc)
            self.pc = (pc_now + 2) & 0xFFFF
        elif op == 0x85:  # MOV dst, src (85 src dst)
            mnem = "MOV {:02X}h,{:02X}h".format(b2, b1)
            val = self.read_direct(b1)
            self.write_direct(b2, val)
            self.pc = (pc_now + 3) & 0xFFFF
        elif op in (0xF6, 0xF7):  # MOV @Ri, A
            ri = op - 0xF6
            addr = self.read_rn(ri)
            mnem = "MOV @R{},A".format(ri)
            self.ram[addr & 0xFF] = self.acc
            self.pc = (pc_now + 1) & 0xFFFF
        elif op == 0xF4:  # CPL A
            mnem = "CPL A"
            self.acc = (~self.acc) & 0xFF
            self.update_p()
            self.pc = (pc_now + 1) & 0xFFFF
        elif op == 0x24:  # ADD A, #imm
            mnem = "ADD A,#{:02X}h".format(b1)
            self.add_with_carry(self.acc, b1, 0)
            self.pc = (pc_now + 2) & 0xFFFF
        elif op == 0x94:  # SUBB A, #imm
            mnem = "SUBB A,#{:02X}h".format(b1)
            self.subb_with_borrow(self.acc, b1)
            self.pc = (pc_now + 2) & 0xFFFF
        elif 0xD8 <= op <= 0xDF:  # DJNZ Rn, rel
            rn = op - 0xD8
            rel = b1 - 256 if b1 >= 128 else b1
            mnem = "DJNZ R{},{}".format(rn, rel)
            nv = (self.read_rn(rn) - 1) & 0xFF
            self.write_rn(rn, nv)
            nxt = (pc_now + 2) & 0xFFFF
            self.pc = ((nxt + rel) & 0xFFFF) if nv != 0 else nxt
        elif op == 0x80:  # SJMP rel
            rel = b1 - 256 if b1 >= 128 else b1
            mnem = "SJMP {:+d}".format(rel)
            self.pc = (pc_now + 2 + rel) & 0xFFFF
        elif op == 0x12:  # LCALL addr16
            target = (b1 << 8) | b2
            ret_pc = (pc_now + 3) & 0xFFFF
            mnem = "LCALL {:04X}h".format(target)
            self.sp = (self.sp + 1) & 0xFF
            self.ram[self.sp] = ret_pc & 0xFF
            self.sp = (self.sp + 1) & 0xFF
            self.ram[self.sp] = (ret_pc >> 8) & 0xFF
            self.pc = target
        elif op == 0x22:  # RET
            mnem = "RET"
            pch = self.ram[self.sp]
            self.sp = (self.sp - 1) & 0xFF
            pcl = self.ram[self.sp]
            self.sp = (self.sp - 1) & 0xFF
            self.pc = (pch << 8) | pcl
        else:
            raise NotImplementedError("Opcode {:02X} at {:04X} not modeled".format(op, pc_now))

        return pc_now, op, mnem


def load_trace_csv(path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(r)
    return rows


def h(val_str):
    return int(val_str, 16)


def check_trace(rom_path, trace_path, max_steps=60, report_out=None):
    rom = load_rom_in(rom_path)
    rows = load_trace_csv(trace_path)
    by_cycle = {int(r["cycle"]): r for r in rows}

    # Instruction decode cycles: booted==1, rd==1, mem_wait==0, wait_data==0
    decodes = [
        r for r in rows
        if r["booted"] == "1" and r["rd"] == "1" and r["mem_wait"] == "0" and r["wait_data"] == "0"
    ]

    model = Golden8051(rom)
    lines = []
    lines.append("# Trace Check Report: `{}` vs `{}`".format(
        os.path.basename(trace_path), os.path.basename(rom_path)
    ))
    lines.append("")
    lines.append("| Step | Decode Cyc | Commit Cyc | Time(ns) | PC | Op | Mnemonic | Exp (ACC/PSW[7:1]/SP/RAM30) | Obs (ACC/PSW/SP/RAM30) | Status |")
    lines.append("|---:|---:|---:|---:|---|---|---|---|---|---|")

    first_div = None
    steps_checked = 0

    for step_idx, dec in enumerate(decodes):
        if step_idx >= max_steps:
            break
        cyc_d = int(dec["cycle"])
        cyc_c = cyc_d + 2
        if cyc_c not in by_cycle:
            break
        obs_d = dec
        obs_c = by_cycle[cyc_c]

        exp_pc, exp_op, mnem = model.step()
        obs_pc = h(obs_d["cur_pc"])
        obs_op = h(obs_d["op1"])

        # In oc8051, if the very next cycle (cyc_d + 1) decodes a stack op (RET/RETI/POP/PUSH/LCALL/ACALL),
        # oc8051_sp begins overlapping SP update at cyc_d + 2 while instruction k commits ALU/RAM.
        sp_obs_row = obs_c
        if step_idx + 1 < len(decodes):
            nxt_dec = decodes[step_idx + 1]
            nxt_cyc = int(nxt_dec["cycle"])
            nxt_op = h(nxt_dec["op1"])
            if nxt_cyc == cyc_d + 1 and (nxt_op in (0x22, 0x32, 0xD0, 0xC0, 0x12) or (nxt_op & 0x1F) == 0x11):
                if (cyc_d + 1) in by_cycle:
                    sp_obs_row = by_cycle[cyc_d + 1]

        diffs = []
        if obs_pc != exp_pc:
            diffs.append("PC: exp={:04X} obs={:04X}".format(exp_pc, obs_pc))
        if obs_op != exp_op:
            diffs.append("OP: exp={:02X} obs={:02X}".format(exp_op, obs_op))

        checks = [
            ("ACC", model.acc, h(obs_c["acc"])),
            ("PSW[7:1]", model.psw & 0xFE, h(obs_c["psw"]) & 0xFE),
            ("SP", model.sp, h(sp_obs_row["sp"])),
            ("R0", model.ram[0x00], h(obs_c["r0"])),
            ("R2", model.ram[0x02], h(obs_c["r2"])),
            ("RAM[30h]", model.ram[0x30], h(obs_c["ram30"])),
            ("RAM[31h]", model.ram[0x31], h(obs_c["ram31"])),
            ("RAM[32h]", model.ram[0x32], h(obs_c["ram32"])),
            ("RAM[33h]", model.ram[0x33], h(obs_c["ram33"])),
            ("RAM[34h]", model.ram[0x34], h(obs_c["ram34"])),
            ("RAM[40h]", model.ram[0x40], h(obs_c["ram40"])),
            ("STK[08h]", model.ram[0x08], h(obs_c["stk08"])),
            ("STK[09h]", model.ram[0x09], h(obs_c["stk09"])),
            ("P0", model.p0, h(obs_c["p0"])),
            ("P1", model.p1, h(obs_c["p1"])),
        ]
        for label, exp_v, obs_v in checks:
            if exp_v != obs_v:
                diffs.append("{}: exp={:02X} obs={:02X}".format(label, exp_v, obs_v))

        status = "PASS" if not diffs else "FAIL"
        lines.append(
            "| {} | {} | {} | {} | {:04X} | {:02X} | `{}` | {:02X} / {:02X} / {:02X} / {:02X} | {:02X} / {:02X} / {:02X} / {:02X} | **{}** |".format(
                step_idx, cyc_d, cyc_c, obs_c["time_ns"],
                exp_pc, exp_op, mnem,
                model.acc, model.psw & 0xFE, model.sp, model.ram[0x30],
                h(obs_c["acc"]), h(obs_c["psw"]), h(sp_obs_row["sp"]), h(obs_c["ram30"]),
                status
            )
        )
        steps_checked += 1

        if diffs and first_div is None:
            first_div = {
                "step": step_idx,
                "decode_cyc": cyc_d,
                "commit_cyc": cyc_c,
                "time_ns": obs_c["time_ns"],
                "pc": "{:04X}".format(exp_pc),
                "op": "{:02X}".format(exp_op),
                "mnem": mnem,
                "diffs": diffs,
            }
            break

        # Stop shortly after entering idle SJMP self-loop (80 FE)
        if exp_op == 0x80 and model.rom[(exp_pc + 1) & 0xFFFF] == 0xFE:
            break

    lines.append("")
    if first_div is None:
        lines.append("**Verdict:** `PASS` ({} instruction boundaries verified against golden 8051 ISA model with 0 divergences).".format(steps_checked))
    else:
        lines.append("**Verdict:** `FAIL` — **First Divergence Detected!**")
        lines.append("")
        lines.append("- **Step:** {}".format(first_div["step"]))
        lines.append("- **Decode Cycle / Commit Cycle:** {} / {} (time={} ns)".format(
            first_div["decode_cyc"], first_div["commit_cyc"], first_div["time_ns"]
        ))
        lines.append("- **PC / Opcode / Instruction:** `{}h` / `{}` / `{}`".format(
            first_div["pc"], first_div["op"], first_div["mnem"]
        ))
        lines.append("- **Mismatched Signals:** {}".format("; ".join(first_div["diffs"])))

    report_txt = "\n".join(lines) + "\n"
    if report_out:
        os.makedirs(os.path.dirname(report_out), exist_ok=True)
        with open(report_out, "w", encoding="utf-8", newline="\n") as f:
            f.write(report_txt)
    print(report_txt)
    return 0 if first_div is None else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rom", required=True)
    ap.add_argument("--trace", required=True)
    ap.add_argument("--out", default=None)
    ap.add_argument("--max-steps", type=int, default=60)
    args = ap.parse_args()
    rc = check_trace(args.rom, args.trace, max_steps=args.max_steps, report_out=args.out)
    sys.exit(rc)


if __name__ == "__main__":
    main()
