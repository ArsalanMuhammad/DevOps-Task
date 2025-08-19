# todoapp
TO-DO Application build on MERN (MySQL-Express-React-Node) Stack.

## Deployment
To deploy the application on AWS use terraform.

### Terraform
Deployment steps of terraform

- Validate if terraform is installated or not.
```sh
terraform version
```

- Initialize terraform
```sh
terraform init
```

- Verify the configurations
```sh
terraform validate
```

- Plan the terraform deployment
```sh
terraform plan -out=tfplan
```

- Deploy the infra
```sh
terraform apply tfplan
```
