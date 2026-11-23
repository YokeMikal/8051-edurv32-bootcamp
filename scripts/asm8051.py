# -*- coding: utf-8 -*-
"""Deterministic 2-pass 8051 assembler generating Intel HEX (.hex), Verilog .in, and .lst."""

import argparse
import hashlib
import os
import re
import sys

SFRS = {
    "P0": 0x80,
    "SP": 0x81,
    "DPL": 0x82,
    "DPH": 0x83,
    "PCON": 0x87,
    "TCON": 0x88,
    "TMOD": 0x89,
    "TL0": 0x8A,
    "TL1": 0x8B,
    "TH0": 0x8C,
    "TH1": 0x8D,
    "P1": 0x90,
    "SCON": 0x98,
    "SBUF": 0x99,
    "P2": 0xA0,
    "IE": 0xA8,
    "P3": 0xB0,
    "IP": 0xB8,
    "PSW": 0xD0,
    "ACC": 0xE0,
    "B": 0xF0,
}

BITS = {
    "IT0": 0x88,
    "IE0": 0x89,
    "IT1": 0x8A,
    "IE1": 0x8B,
    "TR0": 0x8C,
    "TF0": 0x8D,
    "TR1": 0x8E,
    "TF1": 0x8F,
    "EX0": 0xA8,
    "ET0": 0xA9,
    "EX1": 0xAA,
    "ET1": 0xAB,
    "ES": 0xAC,
    "EA": 0xAF,
    "CY": 0xD7,
    "RAM20.0": 0x00,
    "RAM20.1": 0x01,
    "RAM20.2": 0x02,
    "RAM20.3": 0x03,
    "RAM20.4": 0x04,
    "RAM20.5": 0x05,
    "RAM20.6": 0x06,
    "RAM20.7": 0x07,
}
for _port_name, _port_base in (("P0", 0x80), ("P1", 0x90), ("P2", 0xA0), ("P3", 0xB0), ("PSW", 0xD0), ("ACC", 0xE0)):
    for _b in range(8):
        BITS["{}.{}".format(_port_name, _b)] = _port_base + _b

REGS = {"R{}".format(i): i for i in range(8)}


def parse_num(tok):
    t = tok.strip()
    tu = t.upper()
    if tu in SFRS:
        return SFRS[tu]
    if tu in BITS:
        return BITS[tu]
    if t.lower().startswith("0x"):
        return int(t, 16)
    if t.lower().endswith("h"):
        return int(t[:-1], 16)
    if t.lower().endswith("b") and all(c in "01" for c in t[:-1]):
        return int(t[:-1], 2)
    return int(t, 10)


def parse_bit(tok):
    tu = tok.strip().upper()
    if tu in BITS:
        return BITS[tu]
    return parse_num(tok) & 0xFF


def split_operands(op_str):
    if not op_str.strip():
        return []
    return [x.strip() for x in op_str.split(",")]


def parse_lines(src_text):
    items = []
    for lineno, raw in enumerate(src_text.splitlines(), start=1):
        no_cmt = raw.split(";", 1)[0].strip()
        if not no_cmt:
            continue
        label = None
        if ":" in no_cmt:
            lbl_part, rest = no_cmt.split(":", 1)
            label = lbl_part.strip()
            no_cmt = rest.strip()
        if not no_cmt:
            items.append((lineno, label, None, [], raw.strip()))
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*(.*)$", no_cmt)
        if not m:
            raise ValueError("Line {}: cannot parse '{}'".format(lineno, no_cmt))
        mnem = m.group(1).upper()
        ops = split_operands(m.group(2))
        items.append((lineno, label, mnem, ops, raw.strip()))
    return items


def rel8(pc, instr_len, target_tok, labels):
    target = labels[target_tok] if target_tok in labels else parse_num(target_tok)
    rel = target - (pc + instr_len)
    if rel < -128 or rel > 127:
        raise ValueError("Relative target {} out of range from {:04X}".format(target_tok, pc))
    return rel & 0xFF


def encode_inst(pc, mnem, ops, labels, resolve=True):
    if mnem == "NOP":
        assert len(ops) == 0
        return [0x00]
    if mnem == "RET":
        assert len(ops) == 0
        return [0x22]
    if mnem == "RETI":
        assert len(ops) == 0
        return [0x32]
    if mnem == "PUSH" and len(ops) == 1:
        return [0xC0, parse_num(ops[0]) & 0xFF]
    if mnem == "POP" and len(ops) == 1:
        return [0xD0, parse_num(ops[0]) & 0xFF]
    if mnem in ("SETB", "CLR", "CPL") and len(ops) == 1:
        op0 = ops[0].upper()
        if mnem == "CLR" and op0 == "A":
            return [0xE4]
        if mnem == "CPL" and op0 == "A":
            return [0xF4]
        if op0 == "C":
            return [{"SETB": 0xD3, "CLR": 0xC3, "CPL": 0xB3}[mnem]]
        base = {"SETB": 0xD2, "CLR": 0xC2, "CPL": 0xB2}[mnem]
        return [base, parse_bit(ops[0])]
    if mnem in ("JB", "JNB") and len(ops) == 2:
        op = 0x20 if mnem == "JB" else 0x30
        baddr = parse_bit(ops[0])
        r = 0x00 if not resolve else rel8(pc, 3, ops[1], labels)
        return [op, baddr, r]
    if mnem in ("JZ", "JNZ") and len(ops) == 1:
        op = 0x60 if mnem == "JZ" else 0x70
        r = 0x00 if not resolve else rel8(pc, 2, ops[0], labels)
        return [op, r]
    if mnem == "INC" and len(ops) == 1:
        op0 = ops[0].upper()
        if op0 == "A":
            return [0x04]
        if op0 in REGS:
            return [0x08 + REGS[op0]]
        return [0x05, parse_num(ops[0]) & 0xFF]
    if mnem in ("ANL", "ORL", "XRL") and len(ops) == 2:
        dst_u = ops[0].upper()
        if dst_u == "A" and ops[1].startswith("#"):
            op = {"ANL": 0x54, "ORL": 0x44, "XRL": 0x64}[mnem]
            return [op, parse_num(ops[1][1:]) & 0xFF]
        if ops[1].startswith("#"):
            op = {"ANL": 0x53, "ORL": 0x43, "XRL": 0x63}[mnem]
            return [op, parse_num(ops[0]) & 0xFF, parse_num(ops[1][1:]) & 0xFF]
        if ops[1].upper() == "A":
            op = {"ANL": 0x52, "ORL": 0x42, "XRL": 0x62}[mnem]
            return [op, parse_num(ops[0]) & 0xFF]
    if mnem == "MOV" and len(ops) == 2:
        dst_u = ops[0].upper()
        src_u = ops[1].upper()
        if dst_u == "A":
            if ops[1].startswith("#"):
                return [0x74, parse_num(ops[1][1:]) & 0xFF]
            if src_u in REGS:
                return [0xE8 + REGS[src_u]]
            if src_u in ("@R0", "@R1"):
                return [0xE6 + int(src_u[2])]
            return [0xE5, parse_num(ops[1]) & 0xFF]
        if dst_u in REGS:
            if ops[1].startswith("#"):
                return [0x78 + REGS[dst_u], parse_num(ops[1][1:]) & 0xFF]
            if src_u == "A":
                return [0xF8 + REGS[dst_u]]
            return [0xA8 + REGS[dst_u], parse_num(ops[1]) & 0xFF]
        if dst_u in ("@R0", "@R1"):
            idx = int(dst_u[2])
            if src_u == "A":
                return [0xF6 + idx]
            if ops[1].startswith("#"):
                return [0x76 + idx, parse_num(ops[1][1:]) & 0xFF]
            return [0xA6 + idx, parse_num(ops[1]) & 0xFF]
        dst_addr = parse_num(ops[0]) & 0xFF
        if src_u == "A":
            return [0xF5, dst_addr]
        if ops[1].startswith("#"):
            return [0x75, dst_addr, parse_num(ops[1][1:]) & 0xFF]
        if src_u in REGS:
            return [0x88 + REGS[src_u], dst_addr]
        if src_u in ("@R0", "@R1"):
            return [0x86 + int(src_u[2]), dst_addr]
        src_addr = parse_num(ops[1]) & 0xFF
        return [0x85, src_addr, dst_addr]
    if mnem == "ADD" and len(ops) == 2 and ops[0].upper() == "A":
        src_u = ops[1].upper()
        if ops[1].startswith("#"):
            return [0x24, parse_num(ops[1][1:]) & 0xFF]
        if src_u in REGS:
            return [0x28 + REGS[src_u]]
        if src_u in ("@R0", "@R1"):
            return [0x26 + int(src_u[2])]
        return [0x25, parse_num(ops[1]) & 0xFF]
    if mnem == "SUBB" and len(ops) == 2 and ops[0].upper() == "A":
        src_u = ops[1].upper()
        if ops[1].startswith("#"):
            return [0x94, parse_num(ops[1][1:]) & 0xFF]
        if src_u in REGS:
            return [0x98 + REGS[src_u]]
        return [0x95, parse_num(ops[1]) & 0xFF]
    if mnem == "SJMP" and len(ops) == 1:
        r = 0x00 if not resolve else rel8(pc, 2, ops[0], labels)
        return [0x80, r]
    if mnem == "DJNZ" and len(ops) == 2:
        dst_u = ops[0].upper()
        if dst_u in REGS:
            op = 0xD8 + REGS[dst_u]
            r = 0x00 if not resolve else rel8(pc, 2, ops[1], labels)
            return [op, r]
    if mnem in ("LJMP", "LCALL") and len(ops) == 1:
        op = 0x02 if mnem == "LJMP" else 0x12
        if not resolve:
            return [op, 0x00, 0x00]
        target = labels[ops[0]] if ops[0] in labels else parse_num(ops[0])
        return [op, (target >> 8) & 0xFF, target & 0xFF]
    raise ValueError("Unsupported instruction: {} {}".format(mnem, ops))


def assemble(src_path):
    with open(src_path, "r", encoding="utf-8") as f:
        src_text = f.read()
    items = parse_lines(src_text)

    pc = 0
    labels = {}
    for lineno, label, mnem, ops, raw in items:
        if label is not None:
            if label in labels:
                raise ValueError("Duplicate label '{}' at line {}".format(label, lineno))
            labels[label] = pc
        if mnem is None:
            continue
        if mnem == "ORG":
            pc = parse_num(ops[0])
            continue
        if mnem == "END":
            break
        enc = encode_inst(pc, mnem, ops, labels, resolve=False)
        pc += len(enc)

    pc = 0
    max_addr = 0
    rom = {}
    listing = []
    for lineno, label, mnem, ops, raw in items:
        if mnem is None:
            listing.append("              ; [label {} @ {:04X}h]".format(label, labels[label]))
            continue
        if mnem == "ORG":
            pc = parse_num(ops[0])
            listing.append("{:04X}          {}".format(pc, raw))
            continue
        if mnem == "END":
            listing.append("              {}".format(raw))
            break
        enc = encode_inst(pc, mnem, ops, labels, resolve=True)
        for idx, b in enumerate(enc):
            rom[pc + idx] = b
            if pc + idx + 1 > max_addr:
                max_addr = pc + idx + 1
        bhex = " ".join("{:02X}".format(b) for b in enc)
        listing.append("{:04X}  {:<9s} (len={})  {}".format(pc, bhex, len(enc), raw))
        pc += len(enc)

    rom_size = max(((max_addr + 15) // 16) * 16, 16)
    image = [rom.get(a, 0x00) for a in range(rom_size)]

    hex_lines = []
    for addr in range(0, len(image), 16):
        chunk = image[addr:addr + 16]
        rec_len = len(chunk)
        hi = (addr >> 8) & 0xFF
        lo = addr & 0xFF
        s = rec_len + hi + lo + 0 + sum(chunk)
        chk = (-s) & 0xFF
        hex_lines.append(
            ":{:02X}{:04X}00{}{:02X}".format(
                rec_len, addr, "".join("{:02X}".format(b) for b in chunk), chk
            )
        )
    hex_lines.append(":00000001FF")
    hex_text = "\n".join(hex_lines) + "\n"

    in_lines = ["// Generated by scripts/asm8051.py from {}".format(os.path.basename(src_path))]
    for a, b in enumerate(image):
        in_lines.append("{:02X} // {:04X}".format(b, a))
    in_text = "\n".join(in_lines) + "\n"

    lst_text = "\n".join(listing) + "\n"
    return hex_text, in_text, lst_text, image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("asm_file")
    ap.add_argument("--out-prefix", required=True)
    args = ap.parse_args()

    hex_text, in_text, lst_text, image = assemble(args.asm_file)
    for ext, content in ((".hex", hex_text), (".in", in_text), (".lst", lst_text)):
        outp = args.out_prefix + ext
        os.makedirs(os.path.dirname(outp), exist_ok=True)
        with open(outp, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
    sha = hashlib.sha256(hex_text.encode("utf-8")).hexdigest()
    print("Assembled {} -> {}.{{hex,in,lst}} ({} bytes, hex_sha256={})".format(
        args.asm_file, args.out_prefix, len(image), sha
    ))


if __name__ == "__main__":
    main()
