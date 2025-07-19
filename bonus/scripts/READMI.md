for sync argocd
## argocd app sync ftegan-app

for provisioning docker container and pushing to dockerhub
## docker build -t aidarngdev/ftegan:v2 .
## docker push aidarngdev/ftegan:v2

to enter to the pod (deployment container)
## kubectl exec -it <pod-name> -n dev -- /bin/sh


start simple docker with gitlab-ce
and wait for status health
## docker inspect --format='{{.State.Health.Status}}' gitlab-ce

get password
## docker exec -it gitlab-ce grep 'Password:' /etc/gitlab/initial_root_password

enter to gitlab local with username root http://localhost:8880/

