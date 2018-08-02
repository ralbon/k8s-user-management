# k8s-user-management
This script allow you to create users in a namespace using service account and then create associated kubeconfig.
If the namespace doesn't exist, it will create it.
If user exist, it will just add the necessary roles.

## Install
```
$ git clone https://github.com/ralbon/k8s-user-management.git
$ cd k8s-user-management
```

## Usage
`./add-user.sh USER NAMESPACE ROLE"`

ROLE options:
+ `admin`: provide "admin" kubernetes rights in the namespace, and ability to run "kubectl proxy" and access to dashboard through "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/overview?namespace=default". It also provide rights to manage servicemonitor in monitoring namespace (cf CoreOs Prometheus Operator).
+ `dev`: provide "edit" kubernetes rights in the namespace, and ability to run "kubectl top pod"

Example: `./add-user.sh jean.bonbeurre namespace-foo admin`

## Tests

### Prerequisites

Unit and integration tests are described and managed by bats tools (Bash Automated Testing System).
Cf `https://github.com/sstephenson/bats#installing-bats-from-source` to install bats.

###  Run

```
cd bats
bats k8s-namespaces-tu.bats
bats k8s-namespaces-ti.bats
```
