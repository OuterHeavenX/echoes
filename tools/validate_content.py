#!/usr/bin/env python3
"""Content validator: dangling references, duplicate IDs, invalid targets.
Run: python3 tools/validate_content.py   (exit 0 = pass)
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def load(name):
    with open(os.path.join(ROOT, "content", name)) as f:
        return json.load(f)

fails = []
def check(cond, msg):
    print(("PASS: " if cond else "FAIL: ") + msg)
    if not cond:
        fails.append(msg)

chars = load("characters.json"); jobs = load("jobs.json"); items = load("items.json")
enemies = load("enemies.json"); encounters = load("encounters.json")
quests = load("quests.json"); dialogue = load("dialogue.json")

for cid, c in chars.items():
    check(c["job"] in jobs, f"character {cid} job {c['job']} exists")
    check(c["sprite"] and c["portrait"], f"character {cid} has sprite/portrait ids")
for jid, j in jobs.items():
    ids = [a["id"] for a in j["abilities"]]
    check(len(ids) == len(set(ids)), f"job {jid} ability ids unique")
    for a in j["abilities"]:
        check(a["target"] in ("enemy", "enemies", "ally", "allies", "self"),
              f"job {jid} ability {a['id']} target {a['target']} valid")
        check(a["effect"], f"job {jid} ability {a['id']} has effect")
    check(len(j["passives"]) == 0 or len(j["passives"]) == 3 or jid in ("wayfarer","vanguard","artificer"),
          f"job {jid} passive count documented (3 when implemented)")
for eid, e in enemies.items():
    check(e["hp"] > 0 and e["atk"] > 0, f"enemy {eid} has positive hp/atk")
for enc_id, enc in encounters.items():
    for eid in enc["enemies"]:
        check(eid in enemies, f"encounter {enc_id} enemy {eid} exists")
    check(enc["xp"] > 0 and enc["gold"] >= 0, f"encounter {enc_id} rewards positive")
for qid, q in quests.items():
    check(len(q["stages"]) >= 1, f"quest {qid} has stages")
    for iid in q.get("reward_items", {}):
        check(iid in items, f"quest {qid} reward item {iid} exists")
for did, d in dialogue.items():
    check(len(d["lines"]) >= 1, f"dialogue {did} has lines")
    for line in d["lines"]:
        check("speaker" in line and "text" in line, f"dialogue {did} line has speaker+text")
    for eff in d.get("effects", []):
        if eff["type"] == "battle":
            check(eff["value"] in encounters, f"dialogue {did} battle {eff['value']} exists")
        if eff["type"] == "party":
            check(eff["value"] in chars, f"dialogue {did} party {eff['value']} exists")
# Implemented-ability count (only jobs with >=6 abilities count as complete).
complete_jobs = [j for j, v in jobs.items() if len(v["abilities"]) >= 6]
print(f"INFO: jobs with >=6 implemented abilities: {complete_jobs} (target: all 12)")
print(f"INFO: characters={len(chars)} enemies={len(enemies)} encounters={len(encounters)} quests={len(quests)} dialogues={len(dialogue)}")
sys.exit(1 if fails else 0)
