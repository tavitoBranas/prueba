# Demo manual — nginx en EKS

App nginx con contenido desde un ConfigMap, expuesta por un Ingress que crea un **Application Load Balancer** mediante el AWS Load Balancer Controller. Se despliega a mano con `kubectl`, sin pipeline.

```
Internet → ALB (Ingress, clase alb) → Service ClusterIP → Pod nginx ← ConfigMap (index.html)
```

> Antes de este paso: infraestructura creada y `kubectl` configurado (ver pasos 1 a 3 del [README principal](../README.md)). Para una intro a `kubectl` antes de aplicar los manifiestos, ver [DEMO.md](DEMO.md).

## Desplegar

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

## Acceder

El ALB tarda ~2 minutos en quedar activo:

```bash
kubectl get ingress ingress-demo
curl http://$(kubectl get ingress ingress-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Limpieza

Borrar los manifiestos antes de `terraform destroy`: el Ingress tiene que desaparecer para que el controller elimine el ALB; si no, el destroy falla al borrar la VPC.

```bash
kubectl delete -f .
```
