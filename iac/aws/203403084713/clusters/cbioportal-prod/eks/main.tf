locals {
  # Use locals for node groups to enforce required tags
  node_groups = {
    cbioportal = {
      instance_types = ["r7g.xlarge"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 4
      max_size       = 5
      min_size       = 4
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioportal"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbioportal"
      }
    }
    cbio-genie = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 4
      min_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-genie"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-genie"
      }
    }
    cbio-dev = {
      instance_types = ["r7g.medium"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 3
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-dev"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-dev"
      }
    }
    argocd = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
    }
    redis = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 3
      max_size       = 4
      min_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbioportal-redis"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "redis"
      }
    }
    datadog = {
      instance_types = ["t3.small"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "datadog"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "datadog"
      }
    }
    ingress = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "ingress"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "ingress"
      }
    }
    paladin = {
      instance_types = ["t3.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "paladin"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "paladin"
      }
      tags = {
        cdsi-app   = "paladin"
        cdsi-team  = "data-engineering"
        cdsi-owner = "moored2@mskcc.org"
      }
    }
    cbio-session = {
      instance_types = ["r7i.xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 1
      min_size       = 1
      max_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cbio-session"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cbio-session"
      }
      tags = {
        cdsi-app   = "cbioportal"
        cdsi-team  = "data-visualization"
        cdsi-owner = "nasirz1@mskcc.org"
      }
    }
    gn-database = {
      instance_types = ["r7i.2xlarge"]
      ami_type       = "BOTTLEROCKET_x86_64"
      desired_size   = 2
      min_size       = 2
      max_size       = 2
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "gn-database"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "gn-database"
      }
      tags = {
        cdsi-app   = "genome-nexus"
        cdsi-team  = "data-visualization"
        cdsi-owner = "lix2@mskcc.org"
      }
    }
    cellxgene = {
      instance_types = ["r7g.large"]
      ami_type       = "BOTTLEROCKET_ARM_64"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      taints = {
        dedicated = {
          key    = var.TAINT_KEY
          value  = "cellxgene"
          effect = var.TAINT_EFFECT
        }
      }
      labels = {
        (var.LABEL_KEY) = "cellxgene"
      }
      tags = {
        cdsi-app   = "cellxgene"
        cdsi-team  = "data-visualization"
        cdsi-owner = "hweej@mskcc.org"
      }
    }
  }
}

module "eks_cluster" {
  source       = "git::https://github.com/MSK-Staging/cbioportal-terraform.git//src/module/hyc-eks?ref=feature/modularize-base"
  cluster_name = var.CLUSTER_NAME

  # General EKS Config
  cluster_version = var.CLUSTER_VER
  tags = {
    Environment = var.CLUSTER_ENV
  }

  # Network Config
  vpc_id = var.VPC_ID
  azs    = var.VPC_AZ

  # API Controls
  cluster_endpoint_public  = var.API_PUBLIC
  cluster_endpoint_private = var.API_PRIVATE

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    for name, config in local.node_groups : name => merge(config, {
      tags = merge(
        try(config.tags, {}),
        {
          "nodegroup-name" = name
        }
      )
    })
  }
}
