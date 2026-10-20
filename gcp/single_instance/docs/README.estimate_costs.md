
tim@Timothys-MacBook-Air terraform % gcp/scripts/estimate_costs.sh prod

== prod (bluedragon-sre-vuft1e, us-west2-a; compute/disk rate x1.2) ==
  2 x e2-micro VM                                          $0.0202/hr  $  0.48/day  $  14.75/mo
  2 x e2-medium GKE node                                   $0.0804/hr  $  1.93/day  $  58.69/mo
  60 GB pd-balanced disks                                  $0.0099/hr  $  0.24/day  $   7.23/mo
  GKE cluster fee (free-tier credit covers it)             $0.0000/hr  $  0.00/day  $   0.00/mo
  Memorystore Redis Basic 1 GB                             $0.0490/hr  $  1.18/day  $  35.77/mo
  Cloud NAT (3 VMs + 1 IP, excl. data)                     $0.0092/hr  $  0.22/day  $   6.72/mo
  Public VM external IP                                    $0.0050/hr  $  0.12/day  $   3.65/mo
  KMS (3 symmetric + 1 RSA key versions)                   $0.0005/hr  $  0.01/day  $   0.36/mo

== Estimated total: $0.1742/hr   $4.18/day   $127.17/mo ==
   List prices; excludes usage-based charges (see header). GKE clusters on the
   billing account's other projects: 0. The free cluster-fee credit covers
   one cluster on the account; with 'all', it's given to dev.

