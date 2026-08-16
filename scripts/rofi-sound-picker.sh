#!/usr/bin/env python

import json
import os
import shlex
import subprocess
import sys

os.environ["LC_NUMERIC"] = "C"

mode = sys.argv[1] if len(sys.argv) > 1 else "sink"

if mode == "source":
    entities = json.loads(subprocess.check_output(shlex.split("pactl -f json list sources")))
    entities = [e for e in entities if e.get("monitor_of_sink") in (None, "null")]
    current = subprocess.check_output(shlex.split("pactl get-default-source")).decode("utf8").strip()
    setter = "set-default-source"
    prompt = "Input"
else:
    entities = json.loads(subprocess.check_output(shlex.split("pactl -f json list sinks")))
    current = subprocess.check_output(shlex.split("pactl get-default-sink")).decode("utf8").strip()
    setter = "set-default-sink"
    prompt = "Output"

if not entities:
    subprocess.check_call(["dunstify", "-t", "2000", "-r", "2", "-u", "low", f"No {mode}s available"])
    sys.exit(0)

descriptions = [e["description"] for e in entities]
current_idx = next((i for i, e in enumerate(entities) if e["name"] == current), 0)

p = subprocess.Popen(
    shlex.split(f"rofi -dmenu -selected-row {current_idx} -p {shlex.quote(prompt)}"),
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
)
selected = p.communicate(input="\n".join(descriptions).encode("utf8"))[0].decode("utf8").strip()

if p.returncode != 0 or not selected:
    sys.exit(0)

matching = [e["name"] for e in entities if e["description"] == selected]
if not matching:
    sys.exit(1)
selected_name = matching[0]

try:
    subprocess.check_call(["pactl", setter, selected_name])
except subprocess.CalledProcessError:
    subprocess.check_call(["dunstify", "-t", "2000", "-r", "2", "-u", "low", f"Error activating: {selected}"])
    sys.exit(1)
subprocess.check_call(["dunstify", "-t", "2000", "-r", "2", "-u", "low", f"Activated: {selected}"])
