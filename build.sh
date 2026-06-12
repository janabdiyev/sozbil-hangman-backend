#!/usr/bin/env bash
set -o errexit

# Build phase: no persistent disk here — only install deps and collect static.
# migrate + seeding run in the Start Command at runtime when the disk is mounted.

pip install -r requirements.txt
python manage.py collectstatic --no-input
