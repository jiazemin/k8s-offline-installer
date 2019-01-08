#!/usr/bin/python
import yaml
import os
import requests

# Move to script's path as cwd
os.chdir(os.path.dirname(os.path.abspath(__file__)))

def do_mirrors(URLS):
  idx = requests.get("%s/index.yaml" % (URLS,)).text
  data_loaded = yaml.load(idx)
  for i in data_loaded['entries']:
    for j in data_loaded['entries'][i]:
      for k in j['urls']:
        if os.path.exists(k.split("/")[-1]):
          print ">> File Exist, Skipping: %s" % (k.split("/")[-1],)
        else:
          os.system("wget '%s'" % (k,))
        
# ChDir
os.chdir("./mirror")

# Stable
do_mirrors("https://kubernetes-charts.storage.googleapis.com")

# Incubator
do_mirrors("https://kubernetes-charts-incubator.storage.googleapis.com")
