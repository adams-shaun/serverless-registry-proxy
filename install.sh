#!/bin/bash
mkdir helm-test-1.18.0-am1-rc0.7
cd helm-test-1.18.0-am1-rc0.7

latest=$(gcloud secrets versions list gcr-pull-only-service-account-key --limit 1 --format="csv[no-heading](name)")
gcloud secrets versions access $latest --secret=gcr-pull-only-service-account-key > gcr-pull-secret.json

# kind create cluster

kubectl create ns istio-system

# kubectl  create secret docker-registry gar-repo \
#   --docker-server gartifacts.twistio.io \
#   --docker-username _json_key \
#   --docker-email not@val.id \
#   --docker-password="$(cat gcr-pull-secret.json)" \
#   -n istio-system

# kubectl  create secret docker-registry gar-repo \
#   --docker-server gartifacts.twistio.io \
#   --docker-username _json_key \
#   --docker-email not@val.id \
#   --docker-password="$(cat gcr-pull-secret.json)" \
#   -n kube-system

gcloud auth print-access-token | \
  docker login \
  -u oauth2accesstoken \
  --password-stdin "https://gartifacts.twistio.io"

gcloud auth print-access-token | \
  helm registry login -u oauth2accesstoken --password-stdin "https://gartifacts.twistio.io"


cat << EOF> overrides.yml
global:
  hub: gartifacts.twistio.io
  imagePullSecrets:
    - gar-repo
EOF

#oci://gcr.io/f5-gcs-7056-ptg-aspenmesh-cg/tw-istio-private-release/charts

export TAG=1.18.0-am1-rc0.7

helm install istio-base oci://gartifacts.twistio.io/charts/base --version $TAG -n istio-system
helm install istio-cni oci://gartifacts.twistio.io/charts/cni --version $TAG --values overrides.yml -n kube-system
helm install istiod oci://gartifacts.twistio.io/charts/istiod --version $TAG --values overrides.yml -n istio-system


#helm install istio-gateway oci://us-west1-docker.pkg.dev/f5-gcs-7056-ptg-aspenmesh-cg/istio-release/charts/gateway --version $TAG
#helm install istio-ztunnel oci://us-west1-docker.pkg.dev/f5-gcs-7056-ptg-aspenmesh-cg/istio-release/charts/ztunnel --version $TAG