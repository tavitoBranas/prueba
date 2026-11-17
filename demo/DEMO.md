# DEMO — Primeros pasos con kubectl

Intro práctica antes de desplegar la app con los YAML (`00` a `03`). Objetivo: perderle el miedo a `kubectl`, crear un pod a mano, mirarlo por todos lados, romperlo, y entender por qué después usamos Deployments y archivos YAML.

Requisito: cluster creado (`terraform apply` en `infra/`) y `kubectl` configurado:

```bash
aws eks update-kubeconfig --region us-east-1 --name demo-eks
```

Todo se hace en un namespace propio, así al final se borra de un solo comando.

---

## 1. ¿Con qué cluster estoy hablando?

```bash
kubectl config get-contexts        # clusters configurados; * = el activo
kubectl config current-context
kubectl version                    # versión del cliente y del servidor
kubectl cluster-info               # endpoint del API server
```

> `kubectl` es solo un cliente HTTP. Todo lo que hacemos son llamadas al API server del cluster.

## 2. Recorrer el cluster

```bash
kubectl get nodes                  # las máquinas (EC2) que corren los pods
kubectl get nodes -o wide          # + IPs, SO, runtime
kubectl describe node <nombre>     # capacidad, pods asignados, condiciones
```

En `describe node` mirar: `Capacity` / `Allocatable` y la lista `Non-terminated Pods`.

```bash
kubectl get namespaces             # separación lógica dentro del cluster
kubectl get pods -A                # pods de TODOS los namespaces
kubectl get pods -n kube-system    # lo que el cluster necesita para funcionar
```

En `kube-system` ya hay cosas corriendo sin que hayamos desplegado nada: `coredns` (DNS interno), `kube-proxy` y `aws-node` (red), y `aws-load-balancer-controller` (el que crea los ALB).

¿Qué tipos de objetos existen y qué campos tienen?

```bash
kubectl api-resources              # todos los tipos + nombre corto (po, svc, deploy, ns...)
kubectl explain pod                # documentación del recurso
kubectl explain pod.spec.containers.resources
```

## 3. Namespace de trabajo

```bash
kubectl create namespace intro
kubectl config set-context --current --namespace=intro   # namespace por defecto del contexto
kubectl get pods                   # "No resources found in intro namespace."
```

## 4. Primer pod, a mano

```bash
kubectl run web --image=nginx:1.27 --port=80
```

Mirar cómo arranca (Ctrl+C para salir del watch):

```bash
kubectl get pods -w
```

Estados que se ven pasar: `Pending` → `ContainerCreating` → `Running`.

```bash
kubectl get pod web -o wide        # IP del pod y en qué nodo cayó
kubectl get pod web -o yaml        # el objeto completo, como lo guarda el cluster
kubectl describe pod web           # la vista para humanos
```

`describe` es el comando de diagnóstico número uno. Mirar la sección **Events** al final: `Scheduled` → `Pulling` → `Pulled` → `Created` → `Started`. Es la historia del pod.

Sacar un dato puntual:

```bash
kubectl get pod web -o jsonpath='{.status.podIP}'
```

## 5. Hablarle al pod

El pod tiene IP, pero es interna al cluster. Para probar desde la notebook, un túnel:

```bash
kubectl port-forward pod/web 8081:80
```

En otra terminal:

```bash
curl -I http://localhost:8081
curl -s http://localhost:8081/no-existe
```

> `port-forward` es para debug, no para exponer una app. Para eso están Service e Ingress (archivos `02` y `03`).

## 6. Logs

```bash
kubectl logs web                   # stdout/stderr del contenedor
kubectl logs web --tail=5
kubectl logs web --since=1m
kubectl logs -f web                # seguir en vivo (como tail -f)
```

Con `logs -f` abierto, repetir los `curl` del paso anterior: aparecen el `200` y el `404`.

## 7. Entrar al contenedor

```bash
kubectl exec web -- nginx -v                         # un comando suelto
kubectl exec web -- cat /etc/nginx/conf.d/default.conf
kubectl exec -it web -- bash                         # shell interactiva
```

Adentro:

```bash
hostname                           # = nombre del pod
cat /etc/resolv.conf               # DNS apunta a CoreDNS
echo '<h1>Hola desde adentro del pod</h1>' > /usr/share/nginx/html/index.html
exit
```

Con el `port-forward` todavía abierto, `curl http://localhost:8081` devuelve el HTML nuevo.

> Ese cambio vive solo dentro de ese contenedor. Guardar la pregunta para el paso 9: ¿qué pasa si el pod muere?

## 8. Labels y selectores

Los labels son la forma en que Kubernetes relaciona objetos (un Service encuentra sus pods por labels).

```bash
kubectl get pods --show-labels     # kubectl run ya le puso run=web
kubectl label pod web env=demo
kubectl get pods -l env=demo       # filtrar por label
kubectl get pods -l env=prod       # nada
```

## 9. Los pods son mortales

Cortar el `port-forward` (Ctrl+C) y borrar el pod:

```bash
kubectl delete pod web
kubectl get pods                   # No resources found
```

Nadie lo vuelve a crear. Un pod suelto no tiene quién lo cuide, y el `index.html` editado a mano se perdió con él.

## 10. Romper algo a propósito

Imagen con un tag que no existe:

```bash
kubectl run roto --image=nginx:9.99
kubectl get pods                   # ErrImagePull → ImagePullBackOff
kubectl describe pod roto          # Events: "Failed to pull image ... not found"
kubectl get events --sort-by=.lastTimestamp
```

Receta de diagnóstico que sirve siempre:

1. `kubectl get pods` — ¿en qué estado está?
2. `kubectl describe pod <pod>` — ¿qué dicen los Events?
3. `kubectl logs <pod>` (y `--previous` si reinició) — ¿qué dice la app?

```bash
kubectl delete pod roto
```

## 11. Que alguien cuide los pods: Deployment

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=2
kubectl get deployments,replicasets,pods
```

Deployment → ReplicaSet → Pods. Los nombres de los pods lo muestran: `web-<replicaset>-<pod>`.

Borrar un pod y mirar qué pasa:

```bash
kubectl delete pod <uno-de-los-pods>
kubectl get pods                   # ya hay uno nuevo reemplazándolo
```

El Deployment declara un **estado deseado** (2 réplicas) y el cluster trabaja para mantenerlo.

```bash
kubectl scale deployment web --replicas=4
kubectl get pods -o wide           # repartidos entre los nodos

kubectl set image deployment/web nginx=nginx:1.28    # actualizar versión
kubectl rollout status deployment/web                # rolling update, sin corte
kubectl rollout history deployment/web
kubectl rollout undo deployment/web                  # volver atrás
```

Logs de todos los pods del Deployment a la vez:

```bash
kubectl logs -l app=web --prefix --tail=3
```

## 12. De comandos a YAML

Todo lo anterior fue **imperativo**: le dijimos al cluster *qué hacer*. No queda registro, no se puede revisar en un PR, no se puede repetir igual en otro ambiente.

La alternativa es **declarativa**: un archivo que describe *qué queremos que exista*. `kubectl` puede generar ese archivo sin crear nada:

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=2 --dry-run=client -o yaml
```

Esa salida es prácticamente `01-deployment.yaml`. Con el archivo en mano:

```bash
kubectl diff -f archivo.yaml       # qué cambiaría
kubectl apply -f archivo.yaml      # crear o actualizar hasta igualar el archivo
kubectl delete -f archivo.yaml     # borrar lo que el archivo describe
```

## 13. Limpieza

```bash
kubectl delete namespace intro                            # borra todo lo de adentro
kubectl config set-context --current --namespace=default  # volver al namespace default
```

---

## Siguiente paso

Desplegar la app completa con los manifiestos, uno por uno (ver [README.md](README.md)):

```bash
kubectl apply -f 00-configMap.yaml    # el HTML, fuera de la imagen
kubectl apply -f 01-deployment.yaml   # los pods, con probes y recursos
kubectl apply -f 02-services.yaml     # IP y DNS estables para los pods
kubectl apply -f 03-ingress.yaml      # ALB público
```

## Chuleta

| Quiero... | Comando |
|---|---|
| Listar | `kubectl get <tipo> [-n ns] [-A] [-o wide\|yaml] [-l label=valor] [-w]` |
| Detalle + eventos | `kubectl describe <tipo> <nombre>` |
| Logs | `kubectl logs <pod> [-f] [--tail=N] [--previous] [-c contenedor]` |
| Ejecutar adentro | `kubectl exec -it <pod> -- bash` |
| Túnel local | `kubectl port-forward pod/<pod> 8081:80` |
| Crear pod suelto | `kubectl run <nombre> --image=<imagen>` |
| Aplicar archivo | `kubectl apply -f <archivo>` |
| Borrar | `kubectl delete <tipo> <nombre>` / `kubectl delete -f <archivo>` |
| Eventos | `kubectl get events --sort-by=.lastTimestamp` |
| Ayuda de un campo | `kubectl explain <tipo>.<campo>` |
