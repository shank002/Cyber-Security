#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║           PCAP ANALYZER  —  Rocky Linux Edition             ║
║     Reads a .pcap file and renders a terminal dashboard     ║
║                                                             ║
║  Usage:                                                     ║
║    python3 pcap_analyzer.py <file.pcap> [OPTIONS]           ║
║                                                             ║
║  Options:                                                   ║
║    -t, --threshold N   Suspicious pkt threshold  (50)       ║
║    -o, --output FILE   Save plain-text report               ║
║    -T, --top N         Show top N rows per table (10)       ║
║    --no-color          Disable colours                      ║
╚══════════════════════════════════════════════════════════════╝

Dependencies (auto-checked on startup):
  pip install dpkt rich --break-system-packages
"""

import sys
import argparse
import socket
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


# ── Dependency check ─────────────────────────────────────────────
def _check_deps():
    missing = []
    for pkg in ("dpkt", "rich"):
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    if missing:
        print(f"[!] Missing packages: {', '.join(missing)}")
        print(f"    Run:  pip install {' '.join(missing)} --break-system-packages")
        sys.exit(1)

_check_deps()

import dpkt
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.columns import Columns
from rich.text import Text
from rich.rule import Rule
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich import box
from rich.align import Align

console = Console()


# ── Service / risk tables ─────────────────────────────────────────
PORT_NAMES = {
    20: "FTP-data",  21: "FTP",       22: "SSH",       23: "Telnet",
    25: "SMTP",      53: "DNS",       67: "DHCP",      68: "DHCP",
    80: "HTTP",     110: "POP3",     143: "IMAP",     161: "SNMP",
   443: "HTTPS",    445: "SMB",      465: "SMTPS",    514: "Syslog",
   587: "SMTP-sub", 993: "IMAPS",    995: "POP3S",
  1080: "SOCKS",   1433: "MSSQL",   1521: "Oracle",
  3000: "Dev-HTTP", 3306: "MySQL",   3389: "RDP",
  5432: "Postgres", 5900: "VNC",    6379: "Redis",
  6443: "K8s-API",  8080: "HTTP-alt",8443: "HTTPS-alt",
  8888: "Jupyter",  9200: "Elastic",27017: "MongoDB",
}

SUSPICIOUS_PORTS = {21, 22, 23, 3389, 4444, 5900, 6666, 6667, 1337, 31337, 12345, 9001}

TCP_FLAG_BITS = {0x01:"F", 0x02:"S", 0x04:"R", 0x08:"P", 0x10:"A", 0x20:"U"}

def _flag_str(flags: int) -> str:
    return "".join(s for bit, s in sorted(TCP_FLAG_BITS.items()) if flags & bit) or f"0x{flags:02x}"


# ── Colour helpers ────────────────────────────────────────────────
def severity_color(count: int, threshold: int) -> str:
    if count >= threshold:          return "bold red"
    if count >= threshold // 2:     return "bold yellow"
    return "green"

def port_color(port: int) -> str:
    if port in SUSPICIOUS_PORTS:    return "bold red"
    if port in (80, 8080):          return "bold green"
    if port in (443, 8443):         return "bold yellow"
    if port == 22:                  return "bold magenta"
    if port == 53:                  return "bold cyan"
    return "white"

def proto_color(proto: str) -> str:
    return {"TCP":"bold green","UDP":"bold yellow","ICMP":"bold magenta",
            "ARP":"bold cyan","OTHER":"dim white"}.get(proto, "white")


# ── Bar widget ────────────────────────────────────────────────────
def make_bar(value: int, max_val: int, width: int = 20, color: str = "cyan") -> Text:
    if max_val == 0:
        max_val = 1
    filled = min(int(value * width / max_val), width)
    t = Text()
    t.append("█" * filled,           style=color)
    t.append("░" * (width - filled), style="dim")
    return t


# ── IP helpers ────────────────────────────────────────────────────
def ip4(raw: bytes) -> str:
    return socket.inet_ntoa(raw)

def ip6(raw: bytes) -> str:
    return socket.inet_ntop(socket.AF_INET6, raw)


# ── Core analysis ─────────────────────────────────────────────────
class PcapAnalysis:
    def __init__(self, path: str, threshold: int = 50, top_n: int = 10):
        self.path       = Path(path)
        self.threshold  = threshold
        self.top_n      = top_n

        self.total_packets  = 0
        self.total_bytes    = 0
        self.src_ip         = Counter()
        self.dst_ip         = Counter()
        self.proto          = Counter()
        self.dst_port       = Counter()
        self.src_port       = Counter()
        self.ip_pairs       = Counter()
        self.tcp_flags      = Counter()
        self.dns_queries    = Counter()
        self.http_hosts     = Counter()
        self.bytes_per_src  = Counter()
        self.arp_targets    = Counter()
        self.ipv6_src       = Counter()
        self.ipv6_dst       = Counter()

        self.first_ts: float | None = None
        self.last_ts:  float | None = None
        self.alerts: list[str] = []

    # ── Load ─────────────────────────────────────────────────────
    def load(self):
        try:
            fh = open(self.path, "rb")
        except OSError as e:
            console.print(f"[bold red][✘] Cannot open file:[/] {e}")
            sys.exit(1)

        magic = fh.read(4)
        fh.seek(0)

        with Progress(
            SpinnerColumn(),
            TextColumn("[bold cyan]  Parsing [bold]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            console=console,
            transient=True,
        ) as prog:
            task = prog.add_task(self.path.name, total=None)
            count = 0
            try:
                if magic in (b"\xd4\xc3\xb2\xa1", b"\xa1\xb2\xc3\xd4"):
                    reader = dpkt.pcap.Reader(fh)
                else:
                    reader = dpkt.pcapng.Reader(fh)

                for ts, raw in reader:
                    self._parse_packet(ts, raw)
                    count += 1
                    if count % 500 == 0:
                        prog.update(task, advance=500)

            except Exception as e:
                console.print(f"\n[bold red][✘] Parse error:[/] {e}")
                sys.exit(1)
            finally:
                fh.close()

            prog.update(task, total=count, completed=count)

    # ── Per-packet parse ──────────────────────────────────────────
    def _parse_packet(self, ts: float, raw: bytes):
        self.total_packets += 1
        self.total_bytes   += len(raw)

        if self.first_ts is None or ts < self.first_ts:
            self.first_ts = ts
        if self.last_ts is None or ts > self.last_ts:
            self.last_ts = ts

        try:
            eth = dpkt.ethernet.Ethernet(raw)
        except Exception:
            self.proto["OTHER"] += 1
            return

        ip_pkt = eth.data

        # ── ARP ─────────────────────────────────────────────────
        if isinstance(ip_pkt, dpkt.arp.ARP):
            self.proto["ARP"] += 1
            try:
                self.arp_targets[ip4(ip_pkt.tpa)] += 1
            except Exception:
                pass
            return

        # ── IPv4 ─────────────────────────────────────────────────
        if isinstance(ip_pkt, dpkt.ip.IP):
            try:
                src = ip4(ip_pkt.src)
                dst = ip4(ip_pkt.dst)
            except Exception:
                self.proto["OTHER"] += 1
                return

            self.src_ip[src]          += 1
            self.dst_ip[dst]          += 1
            self.bytes_per_src[src]   += len(raw)
            self.ip_pairs[(src, dst)] += 1

            transport = ip_pkt.data

            if isinstance(transport, dpkt.tcp.TCP):
                self.proto["TCP"] += 1
                self.src_port[transport.sport] += 1
                self.dst_port[transport.dport] += 1
                self.tcp_flags[_flag_str(transport.flags)] += 1
                if transport.dport in (80, 8080):
                    try:
                        self._extract_http_host(bytes(transport.data))
                    except Exception:
                        pass

            elif isinstance(transport, dpkt.udp.UDP):
                self.proto["UDP"] += 1
                self.src_port[transport.sport] += 1
                self.dst_port[transport.dport] += 1
                if transport.dport == 53:
                    try:
                        self._extract_dns(bytes(transport.data))
                    except Exception:
                        pass

            elif isinstance(transport, dpkt.icmp.ICMP):
                self.proto["ICMP"] += 1
            else:
                self.proto["OTHER"] += 1
            return

        # ── IPv6 ─────────────────────────────────────────────────
        if isinstance(ip_pkt, dpkt.ip6.IP6):
            try:
                self.ipv6_src[ip6(ip_pkt.src)] += 1
                self.ipv6_dst[ip6(ip_pkt.dst)] += 1
            except Exception:
                pass
            self.proto["OTHER"] += 1
            return

        self.proto["OTHER"] += 1

    def _extract_http_host(self, data: bytes):
        text = data.decode("utf-8", errors="ignore")
        m = re.search(r"^Host:\s*(.+)$", text, re.MULTILINE | re.IGNORECASE)
        if m:
            self.http_hosts[m.group(1).strip()] += 1

    def _extract_dns(self, data: bytes):
        try:
            dns = dpkt.dns.DNS(data)
            if dns.qr == dpkt.dns.DNS_Q:
                for q in dns.qd:
                    self.dns_queries[q.name] += 1
        except Exception:
            pass

    # ── Derived ──────────────────────────────────────────────────
    @property
    def duration(self) -> float:
        if self.first_ts and self.last_ts:
            return max(self.last_ts - self.first_ts, 0.001)
        return 0.001

    @property
    def pps(self) -> float:
        return self.total_packets / self.duration

    def generate_alerts(self):
        self.alerts.clear()

        for ip, c in self.src_ip.items():
            if c >= self.threshold:
                self.alerts.append(f"High-volume source [bold]{ip}[/] — {c:,} packets")

        syn_only = self.tcp_flags.get("S", 0)
        if syn_only > 20:
            self.alerts.append(f"Possible SYN scan: {syn_only:,} SYN-only packets detected")

        for port in SUSPICIOUS_PORTS:
            c = self.dst_port.get(port, 0)
            if c > 0:
                svc = PORT_NAMES.get(port, str(port))
                self.alerts.append(
                    f"Traffic to risky port [bold]{port}[/] ({svc}) — {c:,} packets"
                )

        if self.proto.get("ICMP", 0) > self.threshold:
            self.alerts.append(
                f"ICMP flood suspected: {self.proto['ICMP']:,} ICMP packets"
            )

        if len(self.arp_targets) > 20:
            self.alerts.append(
                f"ARP scan suspected: {len(self.arp_targets)} unique ARP targets"
            )


# ── Rendering ─────────────────────────────────────────────────────
def render(a: PcapAnalysis, output_file: str | None = None):
    a.generate_alerts()
    N = a.top_n

    # ── Header ──────────────────────────────────────────────────
    console.print()
    hdr = Text()
    hdr.append("  ⬡ PCAP ANALYZER  ", style="bold black on cyan")
    hdr.append(f"  Rocky Linux Edition  •  {a.path.name}  ", style="bold cyan on black")
    console.print(Align.center(hdr))
    console.print(Align.center(Text(
        f"  Analyzed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  ", style="dim"
    )))
    console.print()

    # ── Summary panel ────────────────────────────────────────────
    def _ts(t):
        if t is None: return "N/A"
        return datetime.fromtimestamp(t, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    g = Table.grid(padding=(0, 2))
    g.add_column(style="bold cyan",  min_width=22)
    g.add_column(style="bold white", min_width=28)
    g.add_column(style="bold cyan",  min_width=22)
    g.add_column(style="bold white")
    g.add_row("Total Packets",   f"[bold green]{a.total_packets:,}[/]",
              "Total Bytes",     f"[bold green]{a.total_bytes:,}[/]  ({a.total_bytes/1024:.1f} KB)")
    g.add_row("Packets / sec",   f"[bold yellow]{a.pps:.1f}[/]",
              "Duration",        f"[bold yellow]{a.duration:.2f}s[/]")
    g.add_row("First Packet",    _ts(a.first_ts),
              "Last Packet",     _ts(a.last_ts))
    g.add_row("Unique Src IPs",  f"[bold magenta]{len(a.src_ip):,}[/]",
              "Unique Dst IPs",  f"[bold magenta]{len(a.dst_ip):,}[/]")
    g.add_row("Alert Threshold", f"[bold red]≥ {a.threshold} pkts/IP[/]",
              "IPv6 Src / Dst",  f"[dim]{len(a.ipv6_src)} / {len(a.ipv6_dst)}[/]")

    console.print(Panel(g, title="[bold]CAPTURE SUMMARY[/]",
                        border_style="cyan", box=box.ROUNDED))

    # ── Alerts ───────────────────────────────────────────────────
    if a.alerts:
        body = "\n".join(f"  [bold red]⚠[/]  {al}" for al in a.alerts)
        console.print(Panel(body,
            title=f"[bold red]🚨  ALERTS  ({len(a.alerts)} found)[/]",
            border_style="red", box=box.HEAVY))
    else:
        console.print(Panel(
            "  [bold green]✔  No suspicious activity detected.[/]",
            title="[bold green]ALERTS[/]", border_style="green", box=box.ROUNDED))

    console.print(Rule("[bold]TRAFFIC BREAKDOWN[/]", style="cyan"))
    console.print()

    # ── Protocol breakdown ────────────────────────────────────────
    proto_t = Table(box=box.SIMPLE_HEAD, header_style="bold cyan",
                    title="[bold]PROTOCOLS[/]", min_width=46)
    proto_t.add_column("Protocol", style="bold", min_width=9)
    proto_t.add_column("Packets",  justify="right", min_width=9)
    proto_t.add_column("%",        justify="right", min_width=6)
    proto_t.add_column("Bar",      min_width=20)

    total_p  = sum(a.proto.values()) or 1
    proto_mx = max(a.proto.values(), default=1)
    for proto, cnt in a.proto.most_common():
        c = proto_color(proto)
        proto_t.add_row(Text(proto, style=c),
                        Text(f"{cnt:,}", style=c),
                        Text(f"{cnt*100/total_p:.1f}%", style="dim"),
                        make_bar(cnt, proto_mx, 20, c))

    # ── TCP flags breakdown ───────────────────────────────────────
    flag_notes = {
        "S":   ("bold red",    "SYN only — scan?"),
        "SA":  ("bold yellow", "SYN-ACK — open port"),
        "A":   ("dim",         "ACK — data flow"),
        "FA":  ("cyan",        "FIN-ACK — graceful close"),
        "PA":  ("green",       "PSH-ACK — payload"),
        "RA":  ("bold red",    "RST-ACK — reject"),
        "R":   ("bold red",    "RST — hard reset"),
        "F":   ("cyan",        "FIN — close init"),
        "FPA": ("green",       "FIN-PSH-ACK"),
    }
    flag_t = Table(box=box.SIMPLE_HEAD, header_style="bold blue",
                   title="[bold]TCP FLAGS[/]", min_width=38)
    flag_t.add_column("Flags",  min_width=8)
    flag_t.add_column("Count",  justify="right", min_width=8)
    flag_t.add_column("Note",   min_width=20)
    for flags, cnt in a.tcp_flags.most_common(8):
        style, note = flag_notes.get(flags, ("white", ""))
        flag_t.add_row(Text(flags, style=style),
                       Text(f"{cnt:,}", style=style),
                       Text(note, style="dim"))

    console.print(Columns([proto_t, flag_t], equal=False, expand=False))
    console.print()

    # ── Top Source IPs ────────────────────────────────────────────
    src_t = Table(box=box.SIMPLE_HEAD, header_style="bold green",
                  title="[bold]TOP SOURCE IPs[/]", min_width=58)
    src_t.add_column("#",       justify="right", style="dim", width=3)
    src_t.add_column("IP",      min_width=17)
    src_t.add_column("Packets", justify="right", min_width=8)
    src_t.add_column("Bytes",   justify="right", min_width=10)
    src_t.add_column("Status",  min_width=14)
    src_t.add_column("Bar",     min_width=16)

    src_mx = a.src_ip.most_common(1)[0][1] if a.src_ip else 1
    for i, (ip, cnt) in enumerate(a.src_ip.most_common(N), 1):
        c   = severity_color(cnt, a.threshold)
        byt = a.bytes_per_src.get(ip, 0)
        st  = (Text("⚠ SUSPICIOUS", style="bold red")    if cnt >= a.threshold else
               Text("△ ELEVATED",   style="bold yellow") if cnt >= a.threshold//2 else
               Text("✔ OK",         style="green"))
        src_t.add_row(str(i), Text(ip, style=c), Text(f"{cnt:,}", style=c),
                      Text(f"{byt:,}", style="dim"), st, make_bar(cnt, src_mx, 16, c))

    # ── Top Dest IPs ──────────────────────────────────────────────
    dst_t = Table(box=box.SIMPLE_HEAD, header_style="bold yellow",
                  title="[bold]TOP DESTINATION IPs[/]", min_width=50)
    dst_t.add_column("#",       justify="right", style="dim", width=3)
    dst_t.add_column("IP",      min_width=17)
    dst_t.add_column("Packets", justify="right", min_width=8)
    dst_t.add_column("Status",  min_width=14)
    dst_t.add_column("Bar",     min_width=16)

    dst_mx = a.dst_ip.most_common(1)[0][1] if a.dst_ip else 1
    for i, (ip, cnt) in enumerate(a.dst_ip.most_common(N), 1):
        c  = severity_color(cnt, a.threshold)
        st = (Text("⚠ SUSPICIOUS", style="bold red")    if cnt >= a.threshold else
              Text("△ ELEVATED",   style="bold yellow") if cnt >= a.threshold//2 else
              Text("✔ OK",         style="green"))
        dst_t.add_row(str(i), Text(ip, style=c), Text(f"{cnt:,}", style=c),
                      st, make_bar(cnt, dst_mx, 16, c))

    console.print(Columns([src_t, dst_t], equal=False, expand=False))
    console.print()

    # ── Top Dest Ports ────────────────────────────────────────────
    port_t = Table(box=box.SIMPLE_HEAD, header_style="bold magenta",
                   title="[bold]TOP DESTINATION PORTS[/]", min_width=52)
    port_t.add_column("#",       justify="right", style="dim", width=3)
    port_t.add_column("Port",    justify="right", min_width=6)
    port_t.add_column("Service", min_width=11)
    port_t.add_column("Packets", justify="right", min_width=8)
    port_t.add_column("Risk",    min_width=8)
    port_t.add_column("Bar",     min_width=16)

    port_mx = a.dst_port.most_common(1)[0][1] if a.dst_port else 1
    for i, (port, cnt) in enumerate(a.dst_port.most_common(N), 1):
        c    = port_color(port)
        svc  = PORT_NAMES.get(port, "—")
        risk = Text("⚠ RISKY", style="bold red") if port in SUSPICIOUS_PORTS else Text("", style="dim")
        port_t.add_row(str(i), Text(str(port), style=c), Text(svc, style="dim"),
                       Text(f"{cnt:,}", style=c), risk, make_bar(cnt, port_mx, 16, c))

    # ── Top Talker Pairs ──────────────────────────────────────────
    pairs_t = Table(box=box.SIMPLE_HEAD, header_style="bold white",
                    title="[bold]TOP TALKER PAIRS[/]", min_width=50)
    pairs_t.add_column("#",       justify="right", style="dim", width=3)
    pairs_t.add_column("Source",  min_width=17, style="cyan")
    pairs_t.add_column("→",       width=3,  justify="center", style="dim")
    pairs_t.add_column("Dest",    min_width=17, style="yellow")
    pairs_t.add_column("Packets", justify="right", min_width=8)

    for i, ((src, dst), cnt) in enumerate(a.ip_pairs.most_common(N), 1):
        pairs_t.add_row(str(i), src, "→", dst, Text(f"{cnt:,}"))

    console.print(Columns([port_t, pairs_t], equal=False, expand=False))
    console.print()

    # ── DNS + HTTP ────────────────────────────────────────────────
    extra_tables = []
    if a.dns_queries:
        dns_t = Table(box=box.SIMPLE_HEAD, header_style="bold cyan",
                      title="[bold]TOP DNS QUERIES[/]", min_width=46)
        dns_t.add_column("#",      justify="right", style="dim", width=3)
        dns_t.add_column("Domain", min_width=34, style="cyan")
        dns_t.add_column("Count",  justify="right", min_width=7)
        for i, (d, c) in enumerate(a.dns_queries.most_common(N), 1):
            dns_t.add_row(str(i), d, str(c))
        extra_tables.append(dns_t)

    if a.http_hosts:
        http_t = Table(box=box.SIMPLE_HEAD, header_style="bold green",
                       title="[bold]HTTP HOSTS[/]", min_width=44)
        http_t.add_column("#",        justify="right", style="dim", width=3)
        http_t.add_column("Host",     min_width=32, style="green")
        http_t.add_column("Requests", justify="right", min_width=9)
        for i, (h, c) in enumerate(a.http_hosts.most_common(N), 1):
            http_t.add_row(str(i), h, str(c))
        extra_tables.append(http_t)

    if extra_tables:
        console.print(Columns(extra_tables, equal=False, expand=False))
        console.print()

    # ── ARP ───────────────────────────────────────────────────────
    if a.arp_targets:
        arp_t = Table(box=box.SIMPLE_HEAD, header_style="bold cyan",
                      title="[bold]ARP WHO-HAS TARGETS[/]", min_width=36)
        arp_t.add_column("Target IP", min_width=18, style="cyan")
        arp_t.add_column("Requests",  justify="right", min_width=10)
        arp_t.add_column("Note",      min_width=10)
        for ip, cnt in a.arp_targets.most_common(N):
            note = Text("⚠ SCAN?", style="bold red") if cnt > 10 else Text("", style="dim")
            arp_t.add_row(ip, str(cnt), note)
        console.print(arp_t)
        console.print()

    # ── Footer ────────────────────────────────────────────────────
    console.print(Rule(style="dim"))
    console.print(
        f"[dim]  {a.total_packets:,} packets  •  "
        f"{a.duration:.2f}s  •  "
        f"{a.pps:.1f} pkt/s  •  "
        f"{a.total_bytes/1024:.1f} KB  •  "
        f"{len(a.src_ip)} src IPs  •  "
        f"{len(a.dst_ip)} dst IPs[/]"
    )
    console.print()

    # ── Optional save ─────────────────────────────────────────────
    if output_file:
        _save_report(a, output_file)
        console.print(f"[bold green]  ✔  Report saved →[/] [bold]{output_file}[/]\n")


# ── Plain-text report ─────────────────────────────────────────────
def _save_report(a: PcapAnalysis, path: str):
    strip = lambda s: re.sub(r"\[.*?\]", "", s)
    lines = [
        "=" * 60,
        "  PCAP ANALYZER — Text Report",
        f"  File      : {a.path}",
        f"  Generated : {datetime.now()}",
        f"  Threshold : {a.threshold} pkts/IP",
        "=" * 60, "",
        "--- SUMMARY ---",
        f"Total packets  : {a.total_packets:,}",
        f"Total bytes    : {a.total_bytes:,}",
        f"Duration       : {a.duration:.2f}s",
        f"Packets/sec    : {a.pps:.1f}",
        f"Unique src IPs : {len(a.src_ip)}",
        f"Unique dst IPs : {len(a.dst_ip)}",
        "", "--- ALERTS ---",
    ]
    lines += ([f"  [ALERT] {strip(al)}" for al in a.alerts] if a.alerts else ["  None."])
    lines += ["", "--- PROTOCOL BREAKDOWN ---"]
    lines += [f"  {p:<10} {c:>8,}" for p, c in a.proto.most_common()]
    lines += ["", "--- TOP SOURCE IPs ---"]
    for ip, c in a.src_ip.most_common(20):
        lines.append(f"  {ip:<20} {c:>8,}" + ("  [SUSPICIOUS]" if c >= a.threshold else ""))
    lines += ["", "--- TOP DESTINATION IPs ---"]
    for ip, c in a.dst_ip.most_common(20):
        lines.append(f"  {ip:<20} {c:>8,}" + ("  [SUSPICIOUS]" if c >= a.threshold else ""))
    lines += ["", "--- TOP DESTINATION PORTS ---"]
    for port, c in a.dst_port.most_common(20):
        lines.append(f"  {port:<7} {PORT_NAMES.get(port,''):<15} {c:>8,}")
    lines += ["", "--- TCP FLAGS ---"]
    lines += [f"  {f:<12} {c:>8,}" for f, c in a.tcp_flags.most_common()]
    lines += ["", "--- TOP DNS QUERIES ---"]
    lines += [f"  {d:<40} {c:>6,}" for d, c in a.dns_queries.most_common(20)]
    lines.append("")
    Path(path).write_text("\n".join(lines))


# ── CLI ───────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="PCAP Analyzer — terminal dashboard for captured network traffic",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("pcap",
        help="Path to .pcap or .pcapng file")
    parser.add_argument("-t", "--threshold", type=int, default=50, metavar="N",
        help="Suspicious packet count per IP (default: 50)")
    parser.add_argument("-o", "--output", default=None, metavar="FILE",
        help="Save plain-text report to file")
    parser.add_argument("-T", "--top", type=int, default=10, metavar="N",
        help="Show top N rows per table (default: 10)")
    parser.add_argument("--no-color", action="store_true",
        help="Disable colour output")
    args = parser.parse_args()

    global console
    if args.no_color:
        console = Console(no_color=True, highlight=False)

    if not Path(args.pcap).exists():
        console.print(f"[bold red][✘] File not found:[/] {args.pcap}")
        sys.exit(1)

    a = PcapAnalysis(args.pcap, threshold=args.threshold, top_n=args.top)
    a.load()
    render(a, output_file=args.output)


if __name__ == "__main__":
    main()
