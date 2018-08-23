
# VMworld 2018 Demo VIN3762BUS

Thanks for checking out the details of the demo used during my session at VMworld. This is how I deployed Kubernetes over and over for my testing. This is a single master deployment for simplicity. Multiple masters is best practice obviously.

Clone machines with PowerCLI. This script was customized for my environment. Be sure to modify the IP's in the megalab.csv list and change the appropriate settings. This sets the DNS A record and PTR using Powershell too. Make sure you have the appropriate modules installed on comment this out.

```powershell
.\lab_create.ps1
```

Some reason I have to remove the default gw for the iSCSI network. The PowerCLI script required me to set.
Then I run two raw commands to get python installed on Ubuntu16.04 you can just build this into your template. This enables the Ansible modules I want to use to work.
I copy my pub key to the maching to make life easier when running playbooks and later when logging in with ssh.
The demo.yml playbook installs the prereqs for Kubernetes, Kubeadm and Kubectl.

```bash
ansible Demo -m raw -a 'sudo route del -net 0.0.0.0 gw 192.168.230.1 netmask 0.0.0.0 dev ens192' -b -u [user] -k -K
ansible Demo -m raw -a 'apt-get update' -b -u [user] -k -K
ansible Demo -m raw -a 'apt-get -y install python' -b -u [user] -k -K
ansible-playbook copypass.yml -k -K -u [user]
ansible-playbook update.yml -K
ansible-playbook demo.yml -K
ansible Demo-Master -m raw -a 'kubeadm init --apiserver-advertise-address [an IP address]' -b -k -K
```

Copy the token form the output and save it for later.

I am installing weave for the CNI

```bash
ansible Demo-Master -m raw -a 'kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"'

ansible Demo-Worker -m raw -a 'kubeadm join [an IP address]:6443 --token pknb5b.r566r85egywebqka --discovery-token-ca-cert-hash sha256:1268fd74fcccce48228d845f1f4679220f95e29201279752f22f4ef815d4e881'
```

# Install helm
### setup using tiller-rbac

```bash
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh

chmod 700 get_helm.sh
./get_helm.sh
kubectl create -f tiller-rbac.yaml
helm init --service-account tiller
```

## Install PSO
```bash
helm repo add pure https://purestorage.github.io/helm-charts
helm repo update
helm search pure-k8s-plugin
helm install -n pso pure/pure-k8s-plugins -f pure.yaml
```

## Create the default storage class

```bash
kubectl patch storageclass pure -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Label the compute nodes
```bash
kubectl label node node-002 failure-domain.beta.kubernetes.io/zone=A
kubectl label node node-003 failure-domain.beta.kubernetes.io/zone=A
kubectl label node node-004 failure-domain.beta.kubernetes.io/zone=A
kubectl label node node-005 failure-domain.beta.kubernetes.io/zone=A
kubectl label node node-006 failure-domain.beta.kubernetes.io/zone=B
kubectl label node node-007 failure-domain.beta.kubernetes.io/zone=B
kubectl label node node-008 failure-domain.beta.kubernetes.io/zone=B
kubectl label node node-009 failure-domain.beta.kubernetes.io/zone=B
```

I like Weave Scope because 'cool graphs'
```bash
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl port-forward -n weave "$(kubectl get -n weave pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040
```
# Modify your nodes
You may want to add CPU or Memory to a node. This is a script I use to do that to my cluster. Caution it will poweroff all the vm's and change the setting and power them on. Good idea to do this before something important is running.
```powershell
.\lab_modify.ps1
```

# Clean up
```powershell
.\lab_destroy.ps1
```
