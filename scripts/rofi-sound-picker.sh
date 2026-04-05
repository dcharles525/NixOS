#!/usr/bin/env python

import io
import os
import json
import shlex
import subprocess

os.environ["LC_NUMERIC"]="C"
sinks = json.loads(subprocess.check_output(shlex.split("pactl -f json list sinks")))

# like alsa_output.pci-0000_04_00.1.hdmi-stereo
current = (
    subprocess.check_output(shlex.split("pactl get-default-sink"))
    .decode("utf8")
    .strip()
)

descriptions = [sink["description"] for sink in sinks]
current = [i for (i, s) in enumerate(sinks) if s["name"] == current][0]

p = subprocess.Popen(
    shlex.split(f"rofi -dmenu -selected-row {current}"),
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
)
selected = p.communicate(input="\n".join(descriptions).encode("utf8"))[0].decode("utf8").strip()

if p.returncode != 0 or not selected:
    exit(0)

matching = [s["name"] for s in sinks if s["description"] == selected]
if not matching:
    exit(1)
selected_name = matching[0]

try:
    subprocess.check_call(["pactl", "set-default-sink", selected_name])
except subprocess.CalledProcessError:
    subprocess.check_call(["dunstify", "-t", "2000", "-r", "2", "-u", "low", f"Error activating: {selected}"])
    exit(1)
subprocess.check_call(["dunstify", "-t", "2000", "-r", "2", "-u", "low", f"Activated: {selected}"])

