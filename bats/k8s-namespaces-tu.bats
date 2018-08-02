#!/usr/bin/env bats

# Global variable
# Path to the add-user.sh script and templates
ADD_USER_FILES_PATH="../src"

#####################################################
#  UNIT TESTS
#####################################################

@test "testing user_role_heapster template unchanged" {
  expected="
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user-role-heapster
rules:
- apiGroups:
    - \"\"
  resourceNames:
    - \"http:heapster:\"
  resources:
    - services/proxy
  verbs:
    - get"

  actual=$(P_NAMESPACE="foobar" envsubst < $ADD_USER_FILES_PATH/user_role_heapster.yml.j2)

  [ "$actual" == "$expected" ]
}

@test "testing user_role_binding_heapster template unchanged" {
  expected="
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: foo-bar-binding-heapster
subjects:
- kind: ServiceAccount
  name: foo
  namespace: bar
roleRef:
  kind: ClusterRole
  name: user-role-heapster
  apiGroup: rbac.authorization.k8s.io"

  actual=$(P_USER="foo" P_NAMESPACE="bar" envsubst < $ADD_USER_FILES_PATH/user_role_binding_heapster.yml.j2)

  [ "$actual" == "$expected" ]
}

@test "testing user_role_dashboard template unchanged" {
  expected="
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user-role-dashboard
rules:
  - apiGroups: [\"\"]
    resources:
      - services
    verbs: [\"get\", \"list\", \"watch\"]
  - apiGroups: [\"\"]
    resources:
      - services/proxy
    verbs: [\"get\", \"list\", \"watch\", \"create\"]"

  actual=$(P_NAMESPACE="foobar" envsubst < $ADD_USER_FILES_PATH/user_role_dashboard.yml.j2)

  [ "$actual" == "$expected" ]
}

@test "testing user_role_binding_dashboard template unchanged" {
  expected="
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: foo-bar-binding-dashboard
subjects:
- kind: ServiceAccount
  name: foo
  namespace: bar
roleRef:
  kind: ClusterRole
  name: user-role-dashboard
  apiGroup: rbac.authorization.k8s.io"

  actual=$(P_USER="foo" P_NAMESPACE="bar" envsubst < $ADD_USER_FILES_PATH/user_role_binding_dashboard.yml.j2)

  [ "$actual" == "$expected" ]
}

@test "testing dev_role_binding template unchanged" {
  expected="
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: foo-role-binding
  namespace: bar
subjects:
- kind: ServiceAccount
  name: foo
  namespace: bar
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io"

  actual=$(P_USER="foo" P_NAMESPACE="bar" envsubst < $ADD_USER_FILES_PATH/dev_role_binding.yml.j2)

  [ "$actual" == "$expected" ]
}

@test "testing admin_role_binding template unchanged" {
  expected="
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: foo-role-binding
  namespace: bar
subjects:
- kind: ServiceAccount
  name: foo
  namespace: bar
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io"

  actual=$(P_USER="foo" P_NAMESPACE="bar" envsubst < $ADD_USER_FILES_PATH/admin_role_binding.yml.j2)

  [ "$actual" == "$expected" ]
}


@test "testing kube_config_file" template unchanged {
  expected="
kind: Config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: is
    server: dalton
  name: joe
contexts:
- context:
    cluster: joe
    namespace: bar
    user: foo
  name: joe
current-context: joe
users:
- name: foo
  user:
    token: noob"

  actual=$(P_USER="foo" P_NAMESPACE="bar" P_CLUSTER_NAME="joe" P_SERVER="dalton" P_CERT_AUTH_DATA="is" P_USER_TOKEN="noob" envsubst < $ADD_USER_FILES_PATH/kube_config_file.yml.j2)

  [ "$actual" == "$expected" ]
}
