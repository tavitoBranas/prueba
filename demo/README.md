# Demo Kubernetes en AWS EKS (AWS Academy)

App nginx con contenido desde un ConfigMap, expuesta por un Ingress que crea un **Application Load Balancer** mediante el AWS Load Balancer Controller (sin ingress-nginx).

```
Internet → ALB (Ingress, clase alb) → Service ClusterIP → Pod nginx ← ConfigMap (index.html)
```

## Prerequisitos

- AWS CLI con las credenciales del lab de AWS Academy en el perfil `default`
- `terraform` >= 1.5
- `kubectl`

> **AWS Academy**: no se crean roles IAM ni OIDC provider. El cluster y los nodos usan el `LabRole` existente. El AWS Load Balancer Controller toma las credenciales de `LabRole` del nodo vía IMDS, por eso el launch template de los nodos fija el hop limit en 2.

## Paso 1 — Infraestructura

Desde `infra/`:

```bash
terraform init
terraform apply
```

Recursos creados:

- VPC con 3 subnets públicas (tagueadas `kubernetes.io/role/elb` para el ALB)
- EKS cluster + managed node group (2 × `t3.small`, AL2023)
- AWS Load Balancer Controller (Helm, namespace `kube-system`)

Configurar `kubectl`:

```bash
aws eks update-kubeconfig --region us-east-1 --name demo-eks
```

## Paso 2 — Desplegar la app

Desde `demo/`:

```bash
kubectl apply -f 00-configMap.yaml
kubectl apply -f 01-deployment.yaml
kubectl apply -f 02-services.yaml
kubectl apply -f 03-ingress.yaml
```

| Archivo | Recurso |
|---|---|
| `00-configMap.yaml` | ConfigMap `nginx-config` con el `index.html` |
| `01-deployment.yaml` | Deployment nginx que monta el ConfigMap |
| `02-services.yaml` | Service `ClusterIP` puerto 80 |
| `03-ingress.yaml` | Ingress clase `alb`, internet-facing, target-type `ip` |

## Paso 3 — Acceder

El ALB tarda ~2 minutos en quedar activo:

```bash
kubectl get ingress ingress-demo
curl http://$(kubectl get ingress ingress-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Ejemplos de referencia

Manifiestos didácticos, independientes de la app:

| Archivo | Tema |
|---|---|
| `01-probes.yaml` | liveness / readiness (`httpGet`, `exec`, `tcpSocket`) |
| `02-configmap.yaml` | ConfigMap como env vars y como volumen |
| `03-secrets.yaml` | Secrets (el `tls-secret` tiene placeholders, completar antes de aplicar) |
| `04-pvc.yaml` | StorageClass, PV y PVC (requiere el addon EBS CSI driver) |
| `05-all-together.yaml` | Ejemplo completo webapp + Postgres |

## Limpieza

Borrar primero el Ingress para que el controller elimine el ALB; si no, `terraform destroy` falla al borrar la VPC.

```bash
kubectl delete -f 03-ingress.yaml
cd ../infra && terraform destroy
```
