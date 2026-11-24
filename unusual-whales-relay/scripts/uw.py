#!/usr/bin/env python3
"""Unusual Whales relay client (stdlib only).

Base https://ai-tool.indevs.in, prefix /unusualwhales, auth X-API-Key.
Key from env RELAY_API_KEY or key.txt beside this file / in ~/.config/uw-relay/.

  uw.py selftest
  uw.py gex SPY
  uw.py exposure SPY [n]
  uw.py strikes SPY [min] [max]
  uw.py gflow SPY [expiry]
  uw.py flow [n] [ticker]
  uw.py tide
  uw.py darkpool [ticker]
  uw.py raw /api/stock/SPY/gex-levels [query]
  uw.py catalog [keyword]
  uw.py matrix
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://ai-tool.indevs.in"
# Cloudflare blocks the default Python-urllib UA with error 1010; a normal UA is required.
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"
PREFIX = "/unusualwhales"
HERE = os.path.dirname(os.path.abspath(__file__))


def load_key():
    k = os.environ.get("RELAY_API_KEY", "").strip()
    if k:
        return k
    for p in (os.path.join(HERE, "key.txt"),
              os.path.expanduser("~/.config/uw-relay/key.txt")):
        if os.path.isfile(p):
            return open(p, encoding="utf-8").read().strip()
    sys.exit("no key: set RELAY_API_KEY or write key.txt")


def get(path, params=None, retries=3, timeout=45):
    """GET a relay path; path may omit the /unusualwhales prefix."""
    if not path.startswith(PREFIX):
        path = PREFIX + path
    url = BASE + path
    if params:
        url += "?" + (params if isinstance(params, str) else urllib.parse.urlencode(params, doseq=True))
    headers = {"X-API-Key": load_key(), "Accept": "application/json", "User-Agent": UA}
    last = None
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=timeout) as r:
                body = r.read().decode("utf-8", "replace")
                return json.loads(body) if body.strip() else None
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:300]
            last = "HTTP %s %s :: %s" % (e.code, path, detail)
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(1.5 * (attempt + 1))
                continue
            raise RuntimeError(last)
        except (urllib.error.URLError, TimeoutError) as e:
            last = "network %s :: %s" % (path, e)
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(last)


def post(path):
    if not path.startswith(PREFIX):
        path = PREFIX + path
    req = urllib.request.Request(BASE + path, data=b"", method="POST",
                                 headers={"X-API-Key": load_key(), "Accept": "application/json",
                                          "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read().decode("utf-8"))


def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def gex(t):
    return get("/api/stock/%s/gex-levels" % t)["data"]


def exposure(t, n=3):
    rows = get("/api/stock/%s/spot-exposures" % t)["data"]
    return rows[-n:], len(rows)


def strikes(t, lo=None, hi=None):
    p = {}
    if lo:
        p["min_strike"] = lo
    if hi:
        p["max_strike"] = hi
    return get("/api/stock/%s/spot-exposures/strike" % t, p)["data"]


def greek_flow(t, expiry=None):
    p = "/api/stock/%s/greek-flow" % t + ("/" + expiry if expiry else "")
    return get(p)["data"]


def flow_alerts(n=10, ticker=None):
    p = {"limit": n}
    if ticker:
        p["ticker_symbol"] = ticker.upper()
    return get("/api/option-trades/flow-alerts", p)["data"]


def tide():
    return get("/api/market/market-tide")


def darkpool(ticker=None):
    p = "/api/darkpool/%s" % ticker.upper() if ticker else "/api/darkpool/recent"
    return get(p)["data"]


def selftest():
    ok = 0
    try:
        g = gex("SPY")
        print("gex-levels      OK  call_wall=%s flip=%s put_wall=%s asof=%s"
              % (g["call_wall"], g["gamma_flip"], g["put_wall"], g["time"]))
        ok += 1
    except Exception as e:
        print("gex-levels      FAIL  %s" % e)
    try:
        rows, n = exposure("SPY", 1)
        print("spot-exposures  OK  rows=%d price=%s at=%s" % (n, rows[-1]["price"], rows[-1]["time"]))
        ok += 1
    except Exception as e:
        print("spot-exposures  FAIL  %s" % e)
    try:
        a = flow_alerts(1)[0]
        print("flow-alerts     OK  %s %s %s %s prem=%s created=%s"
              % (a["ticker"], a["type"], a["strike"], a["expiry"], a["total_premium"], a["created_at"]))
        ok += 1
    except Exception as e:
        print("flow-alerts     FAIL  %s" % e)
    try:
        d = tide()
        print("market-tide     OK  date=%s rows=%d" % (d.get("date"), len(d.get("data") or [])))
        ok += 1
    except Exception as e:
        print("market-tide     FAIL  %s" % e)
    try:
        print("socket-ticket   OK  expires_in=%s" % post("/socket-ticket")["expires_in"])
        ok += 1
    except Exception as e:
        print("socket-ticket   FAIL  %s" % e)
    try:
        h = get("")
        print("relay-health    OK  status=%s issues=%d plan=%s"
              % (h["operational_health"]["status"], len(h["operational_health"]["issues"]), h["upstream_plan"]))
        ok += 1
    except Exception as e:
        print("relay-health    FAIL  %s" % e)
    print("\n%d/6 checks passed" % ok)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "selftest"
    a1 = sys.argv[2] if len(sys.argv) > 2 else None
    a2 = sys.argv[3] if len(sys.argv) > 3 else None
    a3 = sys.argv[4] if len(sys.argv) > 4 else None
    t = (a1 or "SPY").upper()

    if cmd == "selftest":
        selftest()
    elif cmd == "gex":
        print(json.dumps(gex(t), indent=2))
    elif cmd == "exposure":
        rows, n = exposure(t, int(a2) if a2 else 3)
        print("ticker=%s total=%d" % (t, n))
        for r in rows:
            print("  %s price=%s gamma_oi=%s gamma_dir=%s charm_oi=%s vanna_oi=%s" % (
                r["time"], r["price"], r["gamma_per_one_percent_move_oi"],
                r["gamma_per_one_percent_move_dir"], r["charm_per_one_percent_move_oi"],
                r["vanna_per_one_percent_move_oi"]))
    elif cmd == "strikes":
        rows = strikes(t, a2, a3)
        rows.sort(key=lambda r: f(r.get("strike")) or 0)
        print("ticker=%s rows=%d" % (t, len(rows)))
        for r in rows:
            net = (f(r.get("call_gamma_oi")) or 0) + (f(r.get("put_gamma_oi")) or 0)
            print("  strike=%-8s call=%-16s put=%-16s net=%.2f" % (
                r["strike"], r.get("call_gamma_oi"), r.get("put_gamma_oi"), net))
    elif cmd == "gflow":
        rows = greek_flow(t, a2)
        print("ticker=%s expiry=%s rows=%d" % (t, a2 or "all", len(rows)))
        for r in rows[-12:]:
            print("  %s vol=%-7s tx=%-6s dir_delta=%-12s total_delta=%s" % (
                r["timestamp"], r["volume"], r["transactions"],
                round(f(r["dir_delta_flow"]) or 0), round(f(r["total_delta_flow"]) or 0)))
    elif cmd == "flow":
        rows = flow_alerts(int(a1) if a1 else 10, a2)
        print("alerts=%d" % len(rows))
        for r in rows:
            print("  %s %-6s %-4s %-8s %-11s prem=%-10s vol=%-7s oi=%-7s %s" % (
                r["created_at"], r["ticker"], r["type"], r["strike"], r["expiry"],
                r["total_premium"], r["volume"], r["open_interest"], r.get("alert_rule")))
    elif cmd == "tide":
        d = tide()
        rows = d.get("data") or []
        print("date=%s bars=%d" % (d.get("date"), len(rows)))
        for r in rows[-8:]:
            print("  %s call=%-12.0f put=%-12.0f net_vol=%s" % (
                r["timestamp"], f(r["net_call_premium"]) or 0, f(r["net_put_premium"]) or 0, r["net_volume"]))
    elif cmd == "darkpool":
        rows = darkpool(a1)
        print("prints=%d" % len(rows))
        for r in rows[:20]:
            print("  %s %-6s price=%-10s size=%-7s prem=%-12s %s" % (
                r["executed_at"], r["ticker"], r["price"], r["size"], r["premium"], r["market_center"]))
    elif cmd == "raw":
        if not a1:
            sys.exit("usage: uw.py raw <path> [query]")
        print(json.dumps(get(a1, a2), indent=2)[:20000])
    elif cmd == "catalog":
        cat = json.load(open(os.path.join(HERE, "..", "assets", "catalog.json"), encoding="utf-8"))
        items = cat["endpoints"]
        if a1:
            q = a1.lower()
            items = [e for e in items if q in e["upstream_path"].lower()
                     or q in (e.get("description") or "").lower() or q in e["category"].lower()]
        print("%d of %d endpoints" % (len(items), cat["count"]))
        for e in items:
            print("  [%s] %s  %s" % (e["category"], e["upstream_path"], e.get("description")))
    elif cmd == "matrix":
        import csv
        p = os.path.join(HERE, "..", "assets", "availability-matrix.csv")
        rows = list(csv.DictReader(open(p, encoding="utf-8-sig")))
        from collections import Counter
        print("probed %d" % len(rows))
        for k, v in Counter(r["status"] for r in rows).most_common():
            print("  HTTP %-4s %4d" % (k, v))
        print("  with data: %d" % sum(1 for r in rows if int(r["rows"] or -9) > 0))
        print("\nblocked / empty:")
        for r in rows:
            if r["status"] != "200" or int(r["rows"] or -9) <= 0:
                print("  %-4s %-52s rows=%-4s %s" % (r["status"], r["template"], r["rows"], (r["note"] or "")[:70]))
    else:
        print(__doc__)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        sys.exit(str(e))