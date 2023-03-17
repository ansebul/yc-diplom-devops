# Дипломный практикум в Yandex.Cloud
  
- [Дипломный практикум в Yandex.Cloud](#дипломный-практикум-в-yandexcloud)
  - [Результаты работы - репозитории и ссылки:](#результаты-работы---репозитории-и-ссылки)
    - [Важное замечание:](#важное-замечание)
  - [Этапы выполнения:](#этапы-выполнения)
    - [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
    - [Создание Kubernetes кластера](#создание-kubernetes-кластера)
    - [Создание тестового приложения](#создание-тестового-приложения)
    - [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
    - [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  

---
## Результаты работы - репозитории и ссылки:

- [Конфигурация terraform](./terraform/)

- [Манифесты](./manifests/)

- Репозиторий приложения [на GitHub](https://github.com/ansebul/yc-diplom-devops-application)
 
- Репозиторий приложения [на GitLab](https://ansebul.gitlab.yandexcloud.net/asbulavin/yc-diplom-devops-application)

- [Репозиторий qbec](https://github.com/ansebul/yc-diplom-devops-qbec)

- [Пайплайны CI/CD](https://ansebul.gitlab.yandexcloud.net/asbulavin/yc-diplom-devops-application/-/pipelines/)

- [Тестовое веб-приложение](http://51.250.46.153/)

- [Мониторинг](http://51.250.43.89:30003/d/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&refresh=10s)  ( admin / 261216 )



---
### Важное замечание:

>  При выполнении задания в Yandex Cloud наблюдаются постоянные проблемы с сетью и ДНС. Джобы, которые должны выполняться без ошибок, не проходят. Например: https://ansebul.gitlab.yandexcloud.net/asbulavin/yc-diplom-devops-application/-/jobs/287
>     Дополнительные проблемы создаёт образ Alpine, который используется для GitLab-runner-helper, замена его на Ubuntu не происходит. А замена образа GitLab-runner на Ubuntu не помогает, т.к. порождаются контейнеры GitLab-runner-helper на основе Alpine.
>>         Рекомендации в /docs/executors/kubernetes.md:
>>    `fatal: unable to access 'https://gitlab-ci-token:token@example.com/repo/proj.git/': Could not resolve host: example.com`
>>
>>   If using the `alpine` flavor of the [helper image](../configuration/advanced-configuration.md#helper-image), there can be [DNS issues](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4129) related to Alpine's `musl`'s DNS resolver.
>>
>>   Using the `helper_image_flavor = "ubuntu"` option should resolve this.
>> 
>> Только на 55-м пайплайне удалость добиться результата.


---
## Этапы выполнения:


### Создание облачной инфраструктуры

> 1. Убедимся, что у нас последняя версия terraform и создадим сервисный аккаунт:

```console
$ terraform --version
Terraform v1.4.0
on linux_amd64
```
> ![](./pics/001.s3-service-account.png)

> 2. Создаём s3 backend для terraform:

```console
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ source ./../../set_env.sh
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform validate
Success! The configuration is valid.

abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform fmt
main.tf
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform plan
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform apply -auto-approve
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform output s3_access_key
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ terraform output s3_secret_key
```
>    Прописываем id ключа и ключ в ./../../set_env.sh

> ![](./pics/001.terraform-s3-backend-with-stage.png)

> 3. Подключаем бакет s3 как бэкенд для terraform:

```console
abs@len:~/yc-diplom-devops/terraform/1_init_s3_backend$ cd ../2_diplom/
abs@len:~/yc-diplom-devops/terraform/2_diplom$ source ./../../set_env.sh
abs@len:~/yc-diplom-devops/terraform/2_diplom$ terraform init
```

>  Создадим и переключимся в workspace stage:

```console
abs@len:~/yc-diplom-devops/terraform/2_diplom$ terraform workspace new stage
Created and switched to workspace "stage"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

> Проверим на всякий случай:

```console
abs@len:~/yc-diplom-devops/terraform/2_diplom$ terraform workspace list
  default
* stage
```

> 4. Создаём VPC с подсетями в разных зонах доступности:

```console
abs@len:~/yc-diplom-devops/terraform/2_diplom$ ls -l *.tf
-rw-rw-r-- 1 abs abs  561 мар  9 18:00 main.tf
-rw-rw-r-- 1 abs abs 1478 мар  9 12:18 networks.tf
-rw-rw-r-- 1 abs abs   87 мар  7 17:00 variables.tf
-rw-rw-r-- 1 abs abs  101 мар  9 12:14 vpc.tf

$ terraform validate
$ terraform fmt
$ terraform plan
$ terraform apply -auto-approve
```
> ![](./pics/002.vpc_with_public_subnets.png)

---
### Создание Kubernetes кластера

> Выбираем второй вариант - Yandex Managed Service for Kubernetes.

```console
-rw-rw-r-- 1 abs abs  132 мар  9 19:51 container_registry.tf
-rw-rw-r-- 1 abs abs  211 мар  9 19:39 k8s-kms-key.tf
-rw-rw-r-- 1 abs abs 3561 мар  9 19:45 k8s-node-groups.tf
-rw-rw-r-- 1 abs abs 1828 мар  9 19:43 k8s-regional.tf
-rw-rw-r-- 1 abs abs 4834 мар  4 19:29 k8s-security-groups.tf
-rw-rw-r-- 1 abs abs 1933 мар  9 19:41 k8s-service-account.tf
-rw-rw-r-- 1 abs abs  561 мар  9 18:00 main.tf
-rw-rw-r-- 1 abs abs 1478 мар  9 12:18 networks.tf
-rw-rw-r-- 1 abs abs   87 мар  7 17:00 variables.tf
-rw-rw-r-- 1 abs abs  101 мар  9 12:14 vpc.tf

$ terraform validate
$ terraform fmt
$ terraform plan
$ terraform apply -auto-approve
```

> Смотрим, что у нас за кластер:

```console
$ yc container cluster list
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+
|          ID          |     NAME     |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT   | INTERNAL ENDPOINT |
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+
| catnlupdnlauh0qv28qs | k8s-regional | 2023-03-10 07:19:34 | HEALTHY | RUNNING | https://158.160.40.66 | https://10.1.0.14 |
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+
```

> Подключаемся к кластеру Kubernetes в Облаке Яндекса:

```console
$ yc k8s cluster get-credentials k8s-regional --folder-id b1gdeku5jf5mvckdre6e --external --force

Context 'yc-k8s-regional' was added as default to kubeconfig '/home/abs/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/abs/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'ntlgy-terraform'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
```

> Проверяем подключение к кластеру:

```console
$ kubectl cluster-info --kubeconfig ~/.kube/config
Kubernetes control plane is running at https://158.160.40.66
CoreDNS is running at https://158.160.40.66/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

> Команда kubectl get pods --all-namespaces отрабатывает так:

```console
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                  READY   STATUS    RESTARTS       AGE
kube-system   calico-node-m7cqk                                     1/1     Running   0              4m
kube-system   calico-node-vhtmm                                     1/1     Running   0              2m41s
kube-system   calico-node-zsb84                                     1/1     Running   0              4m42s
kube-system   calico-node-zzg8b                                     1/1     Running   0              4m26s
kube-system   calico-typha-79cddf6bd8-l78k6                         1/1     Running   0              3m31s
kube-system   calico-typha-horizontal-autoscaler-8495b957fc-7j6d4   1/1     Running   0              7m27s
kube-system   calico-typha-vertical-autoscaler-6cc57f94f4-dl2nn     1/1     Running   3 (4m1s ago)   7m26s
kube-system   coredns-5dd66f4c59-4hdh6                              1/1     Running   0              4m18s
kube-system   coredns-5dd66f4c59-hbznp                              1/1     Running   0              7m24s
kube-system   ip-masq-agent-5dcd4                                   1/1     Running   0              4m26s
kube-system   ip-masq-agent-gt82l                                   1/1     Running   0              4m1s
kube-system   ip-masq-agent-htrhm                                   1/1     Running   0              2m42s
kube-system   ip-masq-agent-vm9j4                                   1/1     Running   0              4m42s
kube-system   kube-dns-autoscaler-598db8ff9c-v4bh5                  1/1     Running   0              7m10s
kube-system   kube-proxy-5c2n9                                      1/1     Running   0              2m41s
kube-system   kube-proxy-b8nkz                                      1/1     Running   0              4m
kube-system   kube-proxy-b8vkz                                      1/1     Running   0              4m26s
kube-system   kube-proxy-zgjk5                                      1/1     Running   0              4m42s
kube-system   metrics-server-7574f55985-jncx9                       2/2     Running   0              4m16s
kube-system   npd-v0.8.0-6qknf                                      1/1     Running   0              2m41s
kube-system   npd-v0.8.0-c85rk                                      1/1     Running   0              4m
kube-system   npd-v0.8.0-dh24s                                      1/1     Running   0              4m26s
kube-system   npd-v0.8.0-njv7x                                      1/1     Running   0              4m42s
kube-system   yc-disk-csi-node-v2-9q7bk                             6/6     Running   0              4m42s
kube-system   yc-disk-csi-node-v2-cqksd                             6/6     Running   0              4m1s
kube-system   yc-disk-csi-node-v2-mmfxh                             6/6     Running   0              2m42s
kube-system   yc-disk-csi-node-v2-rjjpg                             6/6     Running   0              4m26s
```
> ![](./pics/004.kubernetes.png)
> ![](./pics/005.nodes.png)
> ![](./pics/006.keys.png)
> ![](./pics/004.kubernetes-node-groups-nodes.png)
> ![](./pics/004.kubernetes-node-groups.png)

---
### Создание тестового приложения

> Установлен Yandex Container Registry:

```console
$ yc container registry list
+----------------------+--------------------+----------------------+
|          ID          |        NAME        |      FOLDER ID       |
+----------------------+--------------------+----------------------+
| crplbtriubvbt4s95dg7 | container-registry | b1gdeku5jf5mvckdre6e |
+----------------------+--------------------+----------------------+
```

> ![](./pics/003.container-registry.png)


> [Git репозиторий с тестовым приложением и Dockerfile](https://github.com/ansebul/yc-diplom-devops-application)

> Образ собран, протестирован и залит в реджестри:
> ![](./pics/007.docker-image.png)


---
### Подготовка cистемы мониторинга и деплой приложения

> 1. Установим в кластер систему мониторинга:

> - Клонировал репозиторий https://github.com/prometheus-operator/kube-prometheus
> - Устанавливаем согласно инструкций в REAMDE.md
  
>  Посмотрим, что там установилось:

```console
$ kubectl get pods --namespace monitoring -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP              NODE           NOMINATED NODE   READINESS GATES
alertmanager-main-0                    1/2     Running   0          5s    10.112.130.15   node-1b-axur   <none>           <none>
alertmanager-main-1                    1/2     Running   0          5s    10.112.128.11   node-1a-acax   <none>           <none>
alertmanager-main-2                    1/2     Running   0          5s    10.112.129.7    node-1c-elit   <none>           <none>
blackbox-exporter-58d99cfb6d-wlgrl     3/3     Running   0          22s   10.112.130.10   node-1b-axur   <none>           <none>
grafana-5b847f4876-t7pgx               0/1     Running   0          17s   10.112.130.11   node-1b-axur   <none>           <none>
kube-state-metrics-ccb6bd9b8-t4blp     3/3     Running   0          16s   10.112.130.12   node-1b-axur   <none>           <none>
node-exporter-9mfs8                    2/2     Running   0          15s   10.2.0.8        node-1b-axur   <none>           <none>
node-exporter-g54jk                    2/2     Running   0          15s   10.3.0.27       node-1c-elit   <none>           <none>
node-exporter-zdssr                    2/2     Running   0          15s   10.1.0.3        node-1a-acax   <none>           <none>
prometheus-adapter-5bf8d6f7c6-l5qww    0/1     Running   0          10s   10.112.130.13   node-1b-axur   <none>           <none>
prometheus-adapter-5bf8d6f7c6-zcmh7    0/1     Running   0          10s   10.112.129.6    node-1c-elit   <none>           <none>
prometheus-k8s-0                       1/2     Running   0          4s    10.112.128.12   node-1a-acax   <none>           <none>
prometheus-k8s-1                       1/2     Running   0          4s    10.112.130.16   node-1b-axur   <none>           <none>
prometheus-operator-5bbdcf679c-5k88r   2/2     Running   0          9s    10.112.130.14   node-1b-axur   <none>           <none>
```
> Теперь зайдём на веб-интерфейсы:

```console
abs@len:~/$ kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```
> ![](./pics/010.Prometheus-metrics.png)
> ![](./pics/010.Prometheus.png)

>  Выбираем Дашборд из доступных по-умолчанию. Смотрим состояние кластера.
```console
abs@len:~/$ kubectl --namespace monitoring port-forward svc/grafana 3000
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```
> ![](./pics/011.Grafana.Dashboards.png)
> ![](./pics/011.Grafana.Dashboards-2.png)

>  Сделаем доступной Графану через http, используя манифест garfana.yaml:

```console
$ kubectl apply -f ./manifests/grafana.yaml 
service/grafana-srv created
networkpolicy.networking.k8s.io/grafana created
```
>  Проверяем:

```console
abs@len:~/devops/_DEVOPS-15/homeworks/Diplom/yc-diplom-devops$ kubectl get svc --namespace monitoring -o wide
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
alertmanager-main       ClusterIP   10.96.210.82    <none>        9093/TCP,8080/TCP            174m   app.kubernetes.io/component=alert-router,app.kubernetes.io/instance=main,app.kubernetes.io/name=alertmanager,app.kubernetes.io/part-of=kube-prometheus
alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   173m   app.kubernetes.io/name=alertmanager
blackbox-exporter       ClusterIP   10.96.215.120   <none>        9115/TCP,19115/TCP           174m   app.kubernetes.io/component=exporter,app.kubernetes.io/name=blackbox-exporter,app.kubernetes.io/part-of=kube-prometheus
grafana                 ClusterIP   10.96.224.189   <none>        3000/TCP                     173m   app.kubernetes.io/component=grafana,app.kubernetes.io/name=grafana,app.kubernetes.io/part-of=kube-prometheus
grafana-srv             NodePort    10.96.145.190   <none>        3000:30003/TCP               7s     app.kubernetes.io/component=grafana,app.kubernetes.io/name=grafana,app.kubernetes.io/part-of=kube-prometheus
kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP            173m   app.kubernetes.io/component=exporter,app.kubernetes.io/name=kube-state-metrics,app.kubernetes.io/part-of=kube-prometheus
node-exporter           ClusterIP   None            <none>        9100/TCP                     173m   app.kubernetes.io/component=exporter,app.kubernetes.io/name=node-exporter,app.kubernetes.io/part-of=kube-prometheus
prometheus-adapter      ClusterIP   10.96.134.155   <none>        443/TCP                      173m   app.kubernetes.io/component=metrics-adapter,app.kubernetes.io/name=prometheus-adapter,app.kubernetes.io/part-of=kube-prometheus
prometheus-k8s          ClusterIP   10.96.247.10    <none>        9090/TCP,8080/TCP            173m   app.kubernetes.io/component=prometheus,app.kubernetes.io/instance=k8s,app.kubernetes.io/name=prometheus,app.kubernetes.io/part-of=kube-prometheus
prometheus-operated     ClusterIP   None            <none>        9090/TCP                     173m   app.kubernetes.io/name=prometheus
prometheus-operator     ClusterIP   None            <none>        8443/TCP                     173m   app.kubernetes.io/component=controller,app.kubernetes.io/name=prometheus-operator,app.kubernetes.io/part-of=kube-prometheus
```

>  Заходим в вебинтерфейс:
>  http://51.250.43.89:30003/d/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&refresh=10s
>  ( admin / 261216 )
> ![](./pics/011.Grafana.Dashboards-NodePort.png)





> 2. Деплой тестового приложения

> Устанавливаю qbec. Создаю конфигурацию:

```console
abs@len:~/yc-diplom-devops-qbec$ qbec init diplom-app
using server URL "https://158.160.40.66" and default namespace "default" for the default environment
wrote diplom-app/params.libsonnet
wrote diplom-app/environments/base.libsonnet
wrote diplom-app/environments/default.libsonnet
wrote diplom-app/qbec.yaml
```
> Редактируем файлы смотрим, что получилось:

```console
abs@len:~/yc-diplom-devops-qbec/diplom-app$ qbec show default
1 components evaluated in 2ms
---
apiVersion: apps/v1
kind: Deployment
labels:
  app: diplom
  component: web
metadata:
  annotations:
    qbec.io/component: app
  labels:
    qbec.io/application: diplom-app
    qbec.io/environment: default
  name: diplom
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: diplom
      component: web
  template:
    metadata:
      labels:
        app: diplom
        component: web
    spec:
      containers:
      - image: cr.yandex/crplbtriubvbt4s95dg7/diplom-app:0.1
        name: diplom
      ports:
      - containerPort: "80"
        name: diplom-cp
        protocol: TCP
```
> Отлично, теперь применим:

```console
abs@len:~/yc-diplom-devops-qbec/diplom-app$ qbec apply default
setting cluster to yc-managed-k8s-catnlupdnlauh0qv28qs
setting context to yc-k8s-regional
cluster metadata load took 226ms
1 components evaluated in 3ms

will synchronize 1 object(s)

Do you want to continue [y/n]: y
1 components evaluated in 3ms
create deployments diplom -n default (source app)
waiting for deletion list to be returned
server objects load took 658ms
---
stats:
  created:
  - deployments diplom -n default (source app)

waiting for readiness of 1 objects
  - deployments diplom -n default

  0s    : deployments diplom -n default :: 0 of 3 updated replicas are available
  1s    : deployments diplom -n default :: 1 of 3 updated replicas are available
  1s    : deployments diplom -n default :: 2 of 3 updated replicas are available
✓ 2s    : deployments diplom -n default :: successfully rolled out (0 remaining)

✓ 2s: rollout complete
command took 4.27s
```

> Посмотрим, что у нас в Кубернетесе:

```console
$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
diplom-6586c546c9-55bbf   1/1     Running   0          47s
diplom-6586c546c9-n5qw7   1/1     Running   0          47s
diplom-6586c546c9-rqltp   1/1     Running   0          47s
```

> Задеплоим LoadBalancer:

```console
abs@len:~/yc-diplom-devops$ kubectl apply -f ./manifests/loadbalancer.yaml 
service/load-balancer created
abs@len:~/yc-diplom-devops$ kubectl get svc -o wide
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE     SELECTOR
kubernetes      ClusterIP      10.96.128.1     <none>          443/TCP        9h      <none>
load-balancer   LoadBalancer   10.96.175.225   51.250.46.153   80:30908/TCP   2m12s   app=diplom,component=web
```

> Теперь откроем в браузере наше "приложение" http://51.250.46.153/:

> ![](./pics/015.web-application.png)


> 3. Задеплоим в кластер Atlantis


> Делаю по иструкции: https://www.runatlantis.io/docs/installation-guide.html
> - Пользователя не создаю, использую существующего.
> - Генерирую токен доступа: https://github.com/settings/profile -> Developer settings -> Personal access tokens (classic): (repo scope)
> - Генерирую рандомную строку (Webhook Secret) на https://www.browserling.com/tools/random-string длиной 32 символа
> - Создаём секреты для доступа к github и yandex-cloud:

```console
$ kubectl create secret generic atlantis-vcs --from-file=secrets/.github_token --from-file=secrets/.github_webhook
secret/atlantis-vcs created

$ kubectl create secret generic atlantis-yc --from-file=secrets/.yc_token --from-file=secrets/.yc_aws_access_key_id --from-file=secrets/.yc_aws_access_secret_key
secret/atlantis-yc created
```
> - Устанавливаю Atlantis через Kubernetes Helm Chart:

```console
$ helm repo add runatlantis https://runatlantis.github.io/helm-charts
"runatlantis" has been added to your repositories
$ cd ../_work_/atlantis
$ helm inspect values runatlantis/atlantis > values.yaml
```
> - Правим конфиг values.yaml: указываем пользователя, токен, вебхук и репозиторий
к которому даём доступ. Остальное оставил по-умолчанию.
> - Устанавливаю Атлантис в кластер кубера:

```console
$ helm install atlantis runatlantis/atlantis -f values.yaml
NAME: atlantis
LAST DEPLOYED: Mon Mar 13 14:56:54 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
2. Atlantis will not start successfully unless at least one of the following sets of credentials are specified (see values.yaml for detailed usage):
  - github
  - githubApp
  - gitlab
  - bitbucket
```

> Посмотрим, что в кластере появилось:

```console
$ kubectl get pods -o wide
NAME                      READY   STATUS    RESTARTS   AGE     IP              NODE           NOMINATED NODE   READINESS GATES
atlantis-0                1/1     Running   0          102s    10.112.129.13   node-1c-elit   <none>           <none>
diplom-6586c546c9-55bbf   1/1     Running   0          2d17h   10.112.128.15   node-1a-acax   <none>           <none>
diplom-6586c546c9-n5qw7   1/1     Running   0          2d17h   10.112.129.10   node-1c-elit   <none>           <none>
diplom-6586c546c9-rqltp   1/1     Running   0          2d17h   10.112.130.19   node-1b-axur   <none>           <none>

$ kubectl get svc -o wide
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE     SELECTOR
atlantis        NodePort       10.96.236.164   <none>          80:30191/TCP   2m      app=atlantis,release=atlantis
kubernetes      ClusterIP      10.96.128.1     <none>          443/TCP        3d4h    <none>
load-balancer   LoadBalancer   10.96.175.225   51.250.46.153   80:30908/TCP   2d18h   app=diplom,component=web

$ kubectl get pvc -o wide
NAME                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE   VOLUMEMODE
atlantis-data-atlantis-0   Bound    pvc-549513ef-3771-44ad-980a-9c3492c610ac   5Gi        RWO            yc-network-hdd   10m   Filesystem

abs@len:~/$ kubectl get secrets
NAME                                  TYPE                                  DATA   AGE
atlantis-vcs                          Opaque                                2      3d3h
atlantis-webhook                      Opaque                                2      3d3h
atlantis-yc                           Opaque                                3      3d3h
```
> Atlantis открывается и доступен веб-интерфейс:

> ![](./pics/017.Atlantis-server-first-check.png)

> Настраиваю вебхук на GitHub:

> ![](./pics/018.GithubWebHook.png)

> Создаю [atlantis.yaml](./terraform/atlantis.yaml) и кладём его в корень репозитория Терраформа. 

> Создаём в репозитории Пулреквест, даём команды Атлантису. Получаем результат:

> ![](./pics/017.03-Atlantis-fail-backend.png)

> Не смотря на созданные секреты для S3 бакета, прописанные в конфиге Атлантиса команды инициализации бэкенда, подружить Atlantis с Yandex Cloud не получилось.


---
### Установка и настройка CI/CD


> 1. Подготавливаем GitLab сервер по инструкции https://cloud.yandex.ru/docs/tutorials/infrastructure-management/gitlab-containers

> ![](./pics/020.1.GitLab-instance.png)


> Создал репозиторий https://ansebul.gitlab.yandexcloud.net/asbulavin/yc-diplom-devops-application и запушил туда приложение.

> Создаю манифест для деплоя приложения `k8s.yaml` и отправляем в репозиторий

> Готовлю конфигурационный файл [values.yaml](./gitlab-runner/values.yaml) для GitLab Runner

> Устанавливаю GitLab Runner из директории с конфигом `values.yaml`:

```console
abs@len:~/helm/gitlab-runer$ helm install --namespace default gitlab-runner -f values.yaml gitlab/gitlab-runner
NAME: gitlab-runner
LAST DEPLOYED: Mon Mar 13 18:41:38 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Your GitLab Runner should now be registered against the GitLab instance reachable at: "https://ansebul.gitlab.yandexcloud.net/"

Runner namespace "default" was found in runners.config template.
```

> В кластере Под появился:

```console
$ kubectl get pods -n default | grep gitlab-runner
gitlab-runner-597577745c-wxds2   1/1     Running   0          75s
```
> В ГитЛабе тоже:
> ![](./pics/020.GitLab_Runner_done.png)

> 2. Настроим сборку и развертывание Docker-образа из CI

> - Создаю переменные окружения GitLab `KUBE_URL` и `KUBE_TOKEN`
> ![](./pics/021.GitLab_variables.png)

> - Настрою сценарий сборки в YAML-файле [.gitlab-ci.yml](https://github.com/ansebul/yc-diplom-devops-application/blob/main/.gitlab-ci.yml)

> - Кладём файл в репозиторий. Срабатывает пайплайн без ошибок и образ появляется в докер-реджрестри.
> ![](./pics/025.Gitlab-cicd-pipeline-status.png)
> ![](./pics/026.New-image-in-the-registry.png)

> Теперь внесём изменение в наше приложение и выкатим новую версию с тегом v0.18:

> ![](./pics/030.stage_build-ok.png)
> ![](./pics/031.stage_build-ok--image.png)

> Старый релиз автоматически заменён новым.
> 
> Было:
> 
> ![](./pics/033.old_release.png)
> 
> Стало:
> 
> ![](./pics/034.new_release.png)

Пайплайн выглядит так:
> ![](./pics/035.pipeline.png)
Посмотреть вживую: https://ansebul.gitlab.yandexcloud.net/asbulavin/yc-diplom-devops-application/-/pipelines/55

> Состояние реджестри:
> ![](./pics/036.container-registry.png)

> Приложение в кластере:
http://51.250.46.153/


