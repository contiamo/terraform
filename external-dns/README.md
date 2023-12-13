# Tailscale Module

This module installs a [Exteranal DNS](https://github.com/kubernetes-sigs/external-dns) EKS addon.

External DNS can be used to manage Service and Ingress DNS records automatically using Route53.

This module is based on [this AWS community article](https://community.aws/tutorials/navigating-amazon-eks/automating-dns-records-for-microservices-using-externaldns).

## Instructions:
- Note that this module is meant to be installed into an EKS cluster.
- Other clusters are supported by External DNS, but not by this module. This is because this module installs a service account and associates an IAM role to it. This is how we ensure that the pod has the permissions to modify the provided Route53 zone.

### Reference In Another TF Project:

```terraform
module "external_dns" {
  # To reference as a private repo use "git@github.com:/contiamo...:
  # source = "git@github.com:contiamo/terraform.git//external-dns"
  source = "github.com/contiamo/terraform//external-dns"
  aws_region         = var.aws_region
  provider_arn       = [ Your EKS OIDC Provider ARN ]
  k8s_namespace      = "kube-system"
  hosted_zone_id     = [ Route53 hosted zone ID ]
  aws_route53_domain = [ Route53 domain ]
}
```


## Using External DNS
Extensive docs can be found in [External DNS project Github](https://github.com/kubernetes-sigs/external-dns/tree/master#readme).

**TL;DR**:

Once installed you can annotate your services in order for DNS records to be created for them:

* For LoadBalancer Services:
  ```bash
  kubectl annotate service nginx "external-dns.alpha.kubernetes.io/hostname=nginx.example.org."
  ```


* For ClusterIP Services:

  Use the internal-hostname annotation to create DNS records with ClusterIP as the target.

  ```bash
  kubectl annotate service nginx "external-dns.alpha.kubernetes.io/internal-hostname=nginx.internal.example.org."
  ```

Optionally, you can customize the TTL value of the resulting DNS record by using the `external-dns.alpha.kubernetes.io/ttl` annotation:
```bash
kubectl annotate service nginx "external-dns.alpha.kubernetes.io/ttl=10"
```
