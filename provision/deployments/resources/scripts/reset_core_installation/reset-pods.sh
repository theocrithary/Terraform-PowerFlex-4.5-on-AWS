#!/bin/bash
kubectl delete pods $(kubectl get pods -n powerflex | egrep '(asmmanager|network|alcm|asmui|sso|legacy|presentationservice)' | awk '{print $1}') -n powerflex
