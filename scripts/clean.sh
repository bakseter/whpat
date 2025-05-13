#!/bin/bash

main() {
    rm -rf manifests/applications/*
    rm -rf manifests/cluster-addons/monitoring
    rm -rf manifests/cluster-addons/oauth2-proxy
    rm -rf manifests/cluster-addons/vertical-pod-autoscaler

    # Get email from user
    read -r -p "Enter your email address (used for cert-manager): " email

    cat <<EOF > manifests/cluster-addons/cert-manager/templates/clusterissuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: $email
    privateKeySecretRef:
      name: letsencrypt
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
      - http01:
          ingress:
            ingressClassName: traefik
EOF

    read -r -p "What is the domain name for your cluster? (e.g. example.com, used for Argo CD): " domain_name
    read -r -p "What is your GitHub repository name? (e.g. my-org/my-repo, used for Argo CD): " repo_name

    cat <<EOF > terraform/extra-manifests/helm-chart.yaml.tpl
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
      domain: argocd.$domain_name

      networkPolicy:
        create: true

    configs:
      repositories:
        argocd:
          url: https://github.com/$repo_name.git

      dex:
        enabled: false
EOF

    cat <<EOF > manifests/cluster-addons/argocd/values.yaml
argo-cd:
  global:
    domain: argocd.$domain_name

    networkPolicy:
      create: true

  configs:
    repositories:
      argocd:
        url: https://github.com/$repo_name.git

    dex:
      enabled: false
EOF

    cat <<EOF > terraform/extra-manifests/applicationset.yaml.tpl
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
        repoURL: https://github.com/$repo_name.git
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
        - repoURL: https://github.com/$repo_name.git
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
EOF

    cat <<EOF > manifests/cluster-addons/argocd/templates/certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ingress-tls
  namespace: argocd
spec:
  secretName: ingress-tls
  dnsNames:
    - argocd.$domain_name
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
EOF

    cat <<EOF > manifests/cluster-addons/argocd/templates/ingressroute.yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: argocd-server
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(\`argocd.$domain_name\`)
      priority: 10
      services:
        - name: argocd-server
          port: 80
      middlewares:
        - name: forwardauth
          namespace: oauth2-proxy
    - kind: Rule
      match: Host(\`argocd.$domain_name\`) && Header(\`Content-Type\`, \`application/grpc\`)
      priority: 11
      services:
        - name: argocd-server
          port: 80
          scheme: h2c
  tls:
    secretName: ingress-tls
EOF
}

main
