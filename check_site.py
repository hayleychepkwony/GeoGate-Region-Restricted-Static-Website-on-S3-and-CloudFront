#!/usr/bin/env python3
"""Check whether a website is reachable from where you are right now.

Built for the geo-restriction demos: connect your VPN to a country, run this,
and get a clean pass/blocked result you can screenshot or log.

Examples
    python3 check_site.py https://dxxxx.cloudfront.net
    python3 check_site.py https://shop.example.com --show-ip --label "VPN: Japan"
    python3 check_site.py https://shop.example.com --label "VPN: Germany" --log results.md

Exit codes: 0 = reachable (2xx/3xx), 1 = blocked/HTTP error (e.g. 403), 2 = network error.
Standard library only, no installs needed.
"""
import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

UA = {"User-Agent": "capstone-site-checker/1.0"}


def my_location(timeout):
    """Ask a public IP-info service where this machine appears to be (opt-in)."""
    try:
        req = urllib.request.Request("https://ipinfo.io/json", headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            d = json.load(r)
        return f"{d.get('ip', '?')} ({d.get('city', '?')}, {d.get('country', '?')})"
    except Exception as exc:  # noqa: BLE001 - best effort only
        return f"unknown ({exc.__class__.__name__})"


def fetch(url, timeout):
    start = time.perf_counter()
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.headers, time.perf_counter() - start, None
    except urllib.error.HTTPError as e:  # 4xx/5xx still carry a response
        return e.code, e.headers, time.perf_counter() - start, None
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        return None, None, time.perf_counter() - start, str(getattr(e, "reason", e))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("url")
    p.add_argument("--label", default="", help="free-text note, e.g. 'VPN: Kenya'")
    p.add_argument("--show-ip", action="store_true", help="look up your apparent IP and country (calls ipinfo.io)")
    p.add_argument("--log", metavar="FILE", help="append a markdown table row to FILE")
    p.add_argument("--timeout", type=float, default=10)
    a = p.parse_args()

    where = my_location(a.timeout) if a.show_ip else "not looked up (use --show-ip)"
    status, headers, secs, err = fetch(a.url, a.timeout)

    if status is None:
        verdict, code = f"NETWORK ERROR: {err}", 2
    elif status < 400:
        verdict, code = "ALLOWED", 0
    else:
        verdict, code = f"BLOCKED / ERROR (HTTP {status})", 1

    via = (headers.get("X-Cache") if headers else None) or "-"
    print(f"Time      : {datetime.now(timezone.utc):%Y-%m-%d %H:%M:%S} UTC")
    print(f"Your IP   : {where}")
    print(f"URL       : {a.url}")
    print(f"Result    : {verdict}")
    print(f"Latency   : {secs * 1000:.0f} ms")
    print(f"X-Cache   : {via}")

    if a.log:
        new = False
        try:
            open(a.log).close()
        except FileNotFoundError:
            new = True
        with open(a.log, "a") as f:
            if new:
                f.write("| Time (UTC) | Label | Apparent IP | HTTP status | Result |\n|---|---|---|---|---|\n")
            f.write(f"| {datetime.now(timezone.utc):%Y-%m-%d %H:%M} | {a.label} | {where} | {status or '-'} | {verdict} |\n")
        print(f"Logged to : {a.log}")
    sys.exit(code)


if __name__ == "__main__":
    main()
