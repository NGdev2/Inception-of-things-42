for sync argocd
## argocd app sync ftegan-app

see status of deployment in real time
## kubectl get deployments -n dev -w

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


run docker runner
## ./start_gitlab_runner.sh 
Enter your GitLab instance URL
## http://host.docker.internal:8880
Enter the GitLab registration token
## bsnK2Z1DBMeyoc6puzrs

file toml /srv/gitlab-runner/config/config.toml

## for check port
lsof -i :8880

for check sync of argocd 
## argocd app get ftegan-app-gitlab | grep "Sync Status"




✅ Password saved to argocd-password.txt
🌐 Setting up ArgoCD port forwarding (localhost:8082)...
💡 Port-forwarding is running in the background. Use 'pkill -f port-forward' to stop it later.
🔍 Testing ArgoCD server accessibility...
✅ ArgoCD server is accessible
🔐 Logging into Argo CD CLI...
'admin:login' logged in successfully
Context 'localhost:8082' updated
✅ Successfully logged into ArgoCD CLI
📝 Creating ArgoCD application template for GitLab...
✅ ArgoCD initialization complete!

📋 ArgoCD Access Information:
  • URL: https://localhost:8082
  • Username: admin
  • Password: 8kQjt07TyD0fFObY

📝 Next Steps:
  1. Access ArgoCD at https://localhost:8082
  2. After GitLab setup, apply: kubectl apply -f argocd-gitlab-app.yaml
  3. Configure ArgoCD to sync with your GitLab repository

🔧 Useful Commands:
  • List apps: argocd app list
  • Check status: kubectl get pods -n argocd
  • Restart port-forward: pkill -f port-forward && kubectl port-forward svc/argocd-server -n argocd 8082:443 &




📋 Next Steps:
1. Access GitLab at: http://localhost:8880
2. Login with username: root
3. Password: LVU3a4WaIxPy0x0i6y0UVhfAWKHIZ8jMMksqBHYg5d0bv9s2zw0OzHf4s0KPVjmm
4. Create a new project: ftegan-k8s-config
5. Push your deployment configs to the new repo
6. Update argocd-gitlab-app.yaml with your repo URL
7. Apply: kubectl apply -f argocd-gitlab-app.yaml

🔧 Useful commands:
Monitor GitLab pods: kubectl get pods -n gitlab -w
Stop port-forward: kill $(lsof -ti:8880)
