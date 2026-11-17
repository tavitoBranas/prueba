# DevOps Demo — App y cluster EKS en AWS

Proyecto de demostración para el curso de DevOps. Contiene una aplicación Go desplegada en AWS EKS, con la infraestructura gestionada por Terraform y dos pipelines de GitHub Actions: uno para la infraestructura y otro para la aplicación.

---

## Arquitectura

```
┌─────────────────────────────────────────────┐
│               GitHub Actions                │
│                                             │
│        build & push ──────► deploy          │
│           (ECR)        (kubectl apply)      │
└─────────────────────────────────────────────┘
                      │
                ┌─────▼──────┐
                │  Amazon    │
                │    ECR     │  ← web-app:{sha}
                └─────┬──────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                            AWS VPC                              │
│                                                                 │
│  Internet ──► ALB (Ingress) ──► Service ClusterIP ──► Pods      │
│               creado por el      web-app:80           web-app   │
│               AWS LB Controller                       :8080     │
│                                                                 │
│               EKS cluster + managed node group (3 subnets)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estructura del proyecto

```
.
├── .github/
│   └── workflows/
│       ├── app.yaml        # Pipeline CI/CD de la aplicación (ECR + EKS)
│       └── infra.yaml      # Pipeline de infraestructura Terraform
├── app/
│   ├── Dockerfile          # Multi-stage build: golang → alpine
│   └── main.go             # Servidor HTTP en Go (puerto 8080)
├── k8s/                    # Manifiestos que aplica el pipeline de la app
│   ├── 00-namespace.yaml
│   ├── 01-deployment.yaml  # image: ${IMAGE_URI} → la reemplaza el pipeline
│   ├── 02-service.yaml
│   └── 03-ingress.yaml     # Ingress clase alb → ALB público
├── infra/                  # Configuración raíz de Terraform (backend, providers, variables)
├── modules/
│   ├── networking/         # VPC, subnets públicas (tagueadas para el ALB), IGW, rutas
│   ├── eks/                # Cluster EKS, launch template, managed node group
│   ├── alb_controller/     # AWS Load Balancer Controller (Helm)
│   └── ecr/                # Repositorio ECR
└── demo/                   # Demo manual de kubectl y manifiestos nginx (ver demo/README.md)
```

---

## Pre-requisitos

- [ ] Cuenta AWS Academy (rol IAM `LabRole` existente)
- [ ] [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) instalado y configurado
- [ ] [Terraform >= 1.5](https://developer.hashicorp.com/terraform/install) instalado
- [ ] [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado
- [ ] [Docker](https://docs.docker.com/get-docker/) instalado (para pruebas locales)
- [ ] Repositorio en GitHub con Actions habilitado
- [ ] Bucket S3 creado para el estado de Terraform (ver paso 1)

> **AWS Academy**: no se crean roles IAM ni OIDC provider. El cluster y los nodos usan `LabRole`. El AWS Load Balancer Controller toma las credenciales de `LabRole` del nodo vía IMDS, por eso el launch template de los nodos fija el hop limit en 2.

---

## Paso 1 — Configurar el backend de Terraform

El estado de Terraform se almacena en S3. Crear el bucket antes de inicializar:

```bash
# Crear el bucket (nombre debe ser único globalmente)
aws s3api create-bucket \
  --bucket mi-proyecto-tfstate \
  --region us-east-1

# Habilitar versionado (permite recuperar estados anteriores)
aws s3api put-bucket-versioning \
  --bucket mi-proyecto-tfstate \
  --versioning-configuration Status=Enabled
```

Luego editar `infra/terraform.tf` y completar el nombre del bucket:

```hcl
backend "s3" {
  bucket  = "mi-proyecto-tfstate"   # ← completar aquí
  key     = "eks-demo/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
}
```

---

## Paso 2 — Configurar secretos en GitHub

Ir a **Settings → Secrets and variables → Actions** y agregar:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key de la cuenta AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret key de la cuenta AWS |
| `AWS_SESSION_TOKEN` | Session token (requerido en cuentas de laboratorio) |

> **Importante:** Las credenciales con `AWS_SESSION_TOKEN` son temporales. Al expirar hay que actualizar los tres secretos.

---

## Paso 3 — Desplegar la infraestructura

### Opción A — Via GitHub Actions (recomendado)

El workflow **Terraform CI/CD** se ejecuta:

- en cada push a `main` que modifique `infra/` o `modules/` → `fmt` → `init` → `validate` → `plan` → `apply`
- en cada pull request hacia `main` → solo `plan`, publicado como comentario en el PR
- manualmente desde **Actions → Terraform CI/CD → Run workflow**

### Opción B — Localmente (útil para debugging)

```bash
cd infra

terraform init      # Inicializar providers y backend
terraform plan      # Ver qué va a crear
terraform apply     # Crear toda la infraestructura (~15 min, el cluster EKS tarda)
```

Al finalizar, Terraform imprime los outputs:

```
Outputs:

cluster_name             = "demo-eks"
ecr_repository_url       = "123456789.dkr.ecr.us-east-1.amazonaws.com/web-app"
kubeconfig_command       = "aws eks update-kubeconfig --region us-east-1 --name demo-eks"
ingress_hostname_command = "kubectl get ingress web-app -n web-app -o jsonpath='...'"
```

Configurar `kubectl`:

```bash
aws eks update-kubeconfig --region us-east-1 --name demo-eks
kubectl get nodes
```

> **Nota:** Terraform crea el cluster, el controller y el repositorio ECR vacío. La app (Deployment, Service, Ingress) la despliega el pipeline de la aplicación (paso 4).

---

## Paso 4 — Desplegar la aplicación

### Opción A — Via GitHub Actions (recomendado)

El workflow **App CI/CD** se dispara con cada push a `main` que modifique `app/` o `k8s/`, o manualmente desde **Actions → App CI/CD → Run workflow**. Ejecuta dos jobs en secuencia:

```
[1] build-and-push → Construye la imagen y la sube a ECR con tags :<git-sha> y :latest
[2] deploy         → update-kubeconfig, reemplaza ${IMAGE_URI} en k8s/*.yaml,
                     kubectl apply y espera el rollout
```

### Opción B — Build, push y deploy manual (solo para pruebas)

```bash
REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com
export IMAGE_URI=$REGISTRY/web-app:manual

# Autenticarse en ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $REGISTRY

# Construir y subir la imagen (los nodos son x86_64)
docker build --platform linux/amd64 -t $IMAGE_URI ./app
docker push $IMAGE_URI

# Aplicar los manifiestos con la imagen
for f in k8s/*.yaml; do envsubst '${IMAGE_URI}' < "$f"; echo "---"; done | kubectl apply -f -
kubectl rollout status deployment/web-app -n web-app
```

---

## Paso 5 — Verificar el despliegue

### Verificar que la aplicación responde

El ALB tarda ~2 minutos en quedar activo después del primer deploy:

```bash
ALB=$(kubectl get ingress web-app -n web-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$ALB/
# Esperado: <h1>Hello from EKS!</h1><p>Pod: web-app-xxxxxxxxx-xxxxx</p>

curl http://$ALB/health
# Esperado: ok
```

### Verificar el estado en el cluster

```bash
kubectl get deploy,pods,svc,ingress -n web-app -o wide
kubectl rollout history deployment/web-app -n web-app
```

### Ver logs de la aplicación

```bash
kubectl logs -n web-app -l app.kubernetes.io/name=web-app --prefix -f
```

### Ver imágenes en ECR

```bash
aws ecr list-images \
  --repository-name web-app \
  --query 'imageIds[*]' \
  --output table
```

---

## Probar la app localmente

```bash
docker build -t web-app-local ./app
docker run -p 8080:8080 web-app-local

# En otra terminal
curl http://localhost:8080/
curl http://localhost:8080/health
```

---

## Módulos Terraform — Referencia rápida

| Módulo | Recursos que crea |
|--------|-------------------|
| `networking` | VPC, subnets públicas con tags `kubernetes.io/role/elb`, Internet Gateway, Route Table |
| `eks` | EKS Cluster, Launch Template (IMDS hop limit 2), Managed Node Group (AL2023) |
| `alb_controller` | Helm release del AWS Load Balancer Controller en `kube-system` |
| `ecr` | Repositorio ECR con scan on push activado |

Los nombres de los recursos (`demo-eks`, `web-app`, `demo-vpc`) se definen en `infra/terraform.tfvars`. Si se cambian, actualizar también el bloque `env` de `.github/workflows/app.yaml` y los manifiestos de `k8s/`.

---

## Destruir la infraestructura

> ⚠️ Esto elimina **todos** los recursos, incluidas las imágenes del repositorio ECR.

Borrar primero el Ingress para que el controller elimine el ALB; si no, `terraform destroy` falla al borrar la VPC (el ALB y sus security groups quedan colgando).

```bash
kubectl delete namespace web-app   # borra Ingress → el controller elimina el ALB
# esperar ~1 min a que el ALB desaparezca

cd infra
terraform destroy
```
