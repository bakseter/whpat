apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - helm-chart.yaml
  - cluster-addons.yaml
  - applications.yaml
