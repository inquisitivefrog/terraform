resource "kubernetes_role" "sre_role_dev1" {
  provider = kubernetes.dev1
  metadata {
    namespace = kubernetes_namespace.app1_dev1.metadata[0].name
    name      = "sre-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "sre_binding_dev1" {
  provider = kubernetes.dev1
  metadata {
    namespace = kubernetes_namespace.app1_dev1.metadata[0].name
    name      = "sre-binding"
  }
  subject {
    kind      = "User"
    name      = "sre"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.sre_role_dev1.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "dba_role_dev1" {
  provider = kubernetes.dev1
  metadata {
    namespace = kubernetes_namespace.app2_dev1.metadata[0].name
    name      = "dba-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "dba_binding_dev1" {
  provider = kubernetes.dev1
  metadata {
    namespace = kubernetes_namespace.app2_dev1.metadata[0].name
    name      = "dba-binding"
  }
  subject {
    kind      = "User"
    name      = "dba"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.dba_role_dev1.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Repeat for dev2 and dev3
resource "kubernetes_role" "sre_role_dev2" {
  provider = kubernetes.dev2
  metadata {
    namespace = kubernetes_namespace.app1_dev2.metadata[0].name
    name      = "sre-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "sre_binding_dev2" {
  provider = kubernetes.dev2
  metadata {
    namespace = kubernetes_namespace.app1_dev2.metadata[0].name
    name      = "sre-binding"
  }
  subject {
    kind      = "User"
    name      = "sre"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.sre_role_dev2.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "dba_role_dev2" {
  provider = kubernetes.dev2
  metadata {
    namespace = kubernetes_namespace.app2_dev2.metadata[0].name
    name      = "dba-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "dba_binding_dev2" {
  provider = kubernetes.dev2
  metadata {
    namespace = kubernetes_namespace.app2_dev2.metadata[0].name
    name      = "dba-binding"
  }
  subject {
    kind      = "User"
    name      = "dba"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.dba_role_dev2.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "sre_role_dev3" {
  provider = kubernetes.dev3
  metadata {
    namespace = kubernetes_namespace.app1_dev3.metadata[0].name
    name      = "sre-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "sre_binding_dev3" {
  provider = kubernetes.dev3
  metadata {
    namespace = kubernetes_namespace.app1_dev3.metadata[0].name
    name      = "sre-binding"
  }
  subject {
    kind      = "User"
    name      = "sre"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.sre_role_dev3.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "dba_role_dev3" {
  provider = kubernetes.dev3
  metadata {
    namespace = kubernetes_namespace.app2_dev3.metadata[0].name
    name      = "dba-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "dba_binding_dev3" {
  provider = kubernetes.dev3
  metadata {
    namespace = kubernetes_namespace.app2_dev3.metadata[0].name
    name      = "dba-binding"
  }
  subject {
    kind      = "User"
    name      = "dba"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.dba_role_dev3.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
