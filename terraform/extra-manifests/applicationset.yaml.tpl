apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: root
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ['missingkey=error']
  generators:
    - git:
        repoURL: https://github.com/baksetercx/whpah.git
        revision: HEAD
        directories:
          - path: manifests/applications/**
          - path: manifests/cluster-addons/**
  template:
    metadata:
      name: '{{.path.basename}}'
      labels:
        bakseter.net/type: '{{trimSuffix "s" (index .path.segments 1)}}'
    spec:
      project: default
      sources:
        - repoURL: https://github.com/baksetercx/whpah.git
          targetRevision: HEAD
          path: '{{.path.path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.path.basename}}'
      syncPolicy:
        automated:
          selfHeal: true
          prune: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
