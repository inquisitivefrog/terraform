resource "kubernetes_role" "sre_role" {
  metadata {
    namespace = kubernetes_namespace.app1.metadata[0].name
    name      = "sre-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "sre_binding" {
  metadata {
    namespace = kubernetes_namespace.app1.metadata[0].name
    name      = "sre-binding"
  }
  subject {
    kind      = "User"
    name      = "sre"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.sre_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "dba_role" {
  metadata {
    namespace = kubernetes_namespace.app2.metadata[0].name
    name      = "dba-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "dba_binding" {
  metadata {
    namespace = kubernetes_namespace.app2.metadata[0].name
    name      = "dba-binding"
  }
  subject {
    kind      = "User"
    name      = "dba"
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.dba_role.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
