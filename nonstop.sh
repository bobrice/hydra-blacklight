#!/bin/bash
while true
do
  RAILS_ENV=test rake yulhy6:ingest
  sleep 1s
done
