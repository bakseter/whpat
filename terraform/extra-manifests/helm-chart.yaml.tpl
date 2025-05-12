apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: argocd
  namespace: argocd
spec:
  repo: https://argoproj.github.io/argo-helm
  chart: argo-cd
  targetNamespace: argocd
  valuesContent: |-
    global:
      domain: argocd.computas.cloud

      networkPolicy:
        create: true

    configs:
      repositories:
        argocd:
          url: https://github.com/baksetercx/whpah-2.git

      dex:
        enabled: false
