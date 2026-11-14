# Compatibility Matrix

Audit date: 2026-11-10.

This document separates the versions currently used by the repository from a
maintained target combination. The target combination is not applied in this
branch because no fresh Ubuntu/OpenStack/Kubernetes environment is available for
runtime validation.

## Decision

Do not describe the current `v1.29` lab as maintained. Keep the current code
behavior unchanged until the target matrix is tested on a disposable OpenStack
stack. Upgrade one layer at a time and rerun bootstrap, Calico, monitoring, and
SMTP tests after each change.

## Version matrix

| Component | Current repository behavior | Maintained target to validate | Compatibility basis | Applied here |
|---|---|---|---|---|
| Kubernetes | `v1.29` package repository | `v1.36.5` from the `v1.36` package channel | Kubernetes 1.36 is maintained; 1.29 is EOL | No |
| containerd | Ubuntu `containerd` package, no exact pin | `2.3.x` LTS, minimum `2.3.0` | containerd lists 2.3.x as LTS and recommends 2.3.0+ for Kubernetes 1.36 | No |
| Calico | `v3.27.0` raw manifest | `v3.33.0` | Calico 3.33 is tested against Kubernetes 1.35, 1.36, and 1.37 | No |
| Helm | Unpinned `get-helm-3` installer from `main` | Helm `4.2.x` | Helm 4.2 supports Kubernetes 1.33 through 1.36 | No |
| kube-prometheus-stack | Latest repository chart at install time | Chart `92.7.0` | Chart metadata requires Kubernetes `>=1.25`; chart upgrade rules require explicit review | No |
| Ansible Core | CI pin `2.17.14` | `2.21.x` on Python 3.12 | Ansible Core 2.21 supports controller Python 3.12-3.14 and target Python 3.9-3.14 | No |

The exact Kubernetes patch shown above is the latest patch observed at the time
of this audit. The package repository is organized by minor release, so the
playbook must also capture and hold the exact installed package versions during
the upgrade test.

## Sources

- [Kubernetes release lifecycle](https://kubernetes.io/releases/)
- [Kubernetes version skew policy](https://kubernetes.io/releases/version-skew-policy/)
- [containerd release and Kubernetes compatibility matrix](https://github.com/containerd/containerd/blob/main/RELEASES.md)
- [Calico Kubernetes requirements](https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
- [Helm version support policy](https://helm.sh/docs/topics/version_skew/)
- [kube-prometheus-stack chart metadata](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/Chart.yaml)
- [Ansible Core support matrix](https://docs.ansible.com/projects/ansible-core/2.21/reference_appendices/release_and_maintenance.html)

## Upgrade gate

Before changing the playbooks, the target matrix must pass all of these checks
on a disposable lab:

1. Heat creates the expected network, ports, floating IPs, and restricted rules.
2. Ansible completes twice with no unexpected changes on the second run.
3. `kubeadm init` completes and the admin kubeconfig has mode `0600`.
4. Workers join and remain Ready after a control-plane rerun.
5. Calico nodes become Ready and pod-to-pod traffic works across nodes.
6. Helm installs the pinned monitoring chart and all monitoring pods become Ready.
7. Alertmanager receives the generated Secret without exposing SMTP values in logs.
8. The stack can be destroyed without leaving resources that were managed by Heat.

Until these checks pass, the current branch should be presented as statically
validated automation and not as a tested deployment.
