output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

# Expuesto para que el node group dependa de que la salida a internet exista
# (los nodos la necesitan para unirse al cluster y durante el destroy).
output "internet_route_ids" {
  value = concat([aws_route.default_route.id], aws_route_table_association.public[*].id)
}
