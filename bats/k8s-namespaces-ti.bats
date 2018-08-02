#!/usr/bin/env bats

# Global variable
# Path to the add-user.sh script and templates
ADD_USER_SCRIPT="../"

#####################################################
#  INTEGRATION TESTS
#####################################################

@test "add-user.sh create namespace and a user when namespace and user do not exist" {
    # GIVEN
    USER="foo"
    NAMESPACE="bats-integration-test"
    ROLE="dev"
    run kubectl delete ns $NAMESPACE

    # WHEN
    run ./$ADD_USER_SCRIPT/add-user.sh $USER $NAMESPACE $ROLE

    # THEN

    [ $status -eq 0 ]

    EXPECTED_NAMESPACE=$NAMESPACE
    ACTUAL_NAMESPACE="$(kubectl get ns |grep -v NAME |grep -w $NAMESPACE |awk '{print $1}')"

    [ "$ACTUAL_NAMESPACE" == "$EXPECTED_NAMESPACE" ]

    EXPECTED_USER=$USER
    ACTUAL_USER=$(kubectl get sa -n $NAMESPACE |grep -v NAME |grep -w $USER |awk '{print $1}')

    [ "$ACTUAL_USER" == "$EXPECTED_USER" ]

    run kubectl delete ns $NAMESPACE
    run rm $USER-$NAMESPACE-kubeconfig
}

@test "add-user.sh kubeconfig generated should be able to access to cluster" {
    # GIVEN
    USER="foo"
    NAMESPACE="bats-integration-test"
    ROLE="dev"
    run kubectl delete ns $NAMESPACE

    # WHEN
    run ./$ADD_USER_SCRIPT/add-user.sh $USER $NAMESPACE $ROLE

    # THEN

    [ $status -eq 0 ]

     export KUBECONFIG=$USER-$NAMESPACE-kubeconfig
     run kubectl get all

    [ $status -eq 0 ]

    run kubectl delete ns $NAMESPACE
    run rm $USER-$NAMESPACE-kubeconfig
}

@test "add-user.sh doesnt create user when role is not admin or dev" {
    # GIVEN
    USER="foo"
    NAMESPACE="bats-integration-test"
    ROLE="bar"
    run kubectl delete ns $NAMESPACE

    # WHEN
    run ./$ADD_USER_SCRIPT/add-user.sh $USER $NAMESPACE $ROLE

    # THEN
    [ $status -eq 1 ]
    [ "$output" == "ROLE must be set to admin or dev" ]

    run kubectl delete ns $NAMESPACE
    run rm $USER-$NAMESPACE-kubeconfig
}

@test "Clean bats-integration-test namespace" {
    USER="foo"
    NAMESPACE="bats-integration-test"

    run kubectl delete ns $NAMESPACE
    run rm $USER-$NAMESPACE-kubeconfig
}
