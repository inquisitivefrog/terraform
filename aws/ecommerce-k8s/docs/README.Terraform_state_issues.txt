
tim@Tims-MBP ecommerce-k8s % terraform state push errored.tfstate
Failed to write state: cannot overwrite existing state with serial 8 with a different state that has the same serial
tim@Tims-MBP ecommerce-k8s % aws s3 cp s3://bluedragon-ecommerce-terraform-state/ecommerce-k8s/terraform.tfstate current.tfstate
download: s3://bluedragon-ecommerce-terraform-state/ecommerce-k8s/terraform.tfstate to ./current.tfstate
tim@Tims-MBP ecommerce-k8s % cat errored.tfstate | jq . > errored.tfstate.json
tim@Tims-MBP ecommerce-k8s % view errored.tfstate.json
tim@Tims-MBP ecommerce-k8s % diff -u current.tfstate errored.tfstate.json
--- current.tfstate	2025-06-10 14:19:29
+++ errored.tfstate.json	2025-06-10 14:26:38
@@ -42,14 +42,6 @@
           "identity_schema_version": 0
         }
       ]
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "data",
-      "type": "aws_eks_addon_version",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
     },
     {
       "module": "module.eks.module.eks",
@@ -357,81 +349,6 @@
     },
     {
       "module": "module.eks.module.eks",
-      "mode": "data",
-      "type": "tls_certificate",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/tls\"]",
-      "instances": [
-        {
-          "index_key": 0,
-          "schema_version": 0,
-          "attributes": {
-            "certificates": [
-              {
-                "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIEdTCCA12gAwIBAgIJAKcOSkw0grd/MA0GCSqGSIb3DQEBCwUAMGgxCzAJBgNV\nBAYTAlVTMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTIw\nMAYDVQQLEylTdGFyZmllbGQgQ2xhc3MgMiBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0\neTAeFw0wOTA5MDIwMDAwMDBaFw0zNDA2MjgxNzM5MTZaMIGYMQswCQYDVQQGEwJV\nUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTElMCMGA1UE\nChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjE7MDkGA1UEAxMyU3RhcmZp\nZWxkIFNlcnZpY2VzIFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEi\nMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVDDrEKvlO4vW+GZdfjohTsR8/\ny8+fIBNtKTrID30892t2OGPZNmCom15cAICyL1l/9of5JUOG52kbUpqQ4XHj2C0N\nTm/2yEnZtvMaVq4rtnQU68/7JuMauh2WLmo7WJSJR1b/JaCTcFOD2oR0FMNnngRo\nOt+OQFodSk7PQ5E751bWAHDLUu57fa4657wx+UX2wmDPE1kCK4DMNEffud6QZW0C\nzyyRpqbn3oUYSXxmTqM6bam17jQuug0DuDPfR+uxa40l2ZvOgdFFRjKWcIfeAg5J\nQ4W2bHO7ZOphQazJ1FTfhy/HIrImzJ9ZVGif/L4qL8RVHHVAYBeFAlU5i38FAgMB\nAAGjgfAwge0wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0O\nBBYEFJxfAN+qAdcwKziIorhtSpzyEZGDMB8GA1UdIwQYMBaAFL9ft9HO3R+G9FtV\nrNzXEMIOqYjnME8GCCsGAQUFBwEBBEMwQTAcBggrBgEFBQcwAYYQaHR0cDovL28u\nc3MyLnVzLzAhBggrBgEFBQcwAoYVaHR0cDovL3guc3MyLnVzL3guY2VyMCYGA1Ud\nHwQfMB0wG6AZoBeGFWh0dHA6Ly9zLnNzMi51cy9yLmNybDARBgNVHSAECjAIMAYG\nBFUdIAAwDQYJKoZIhvcNAQELBQADggEBACMd44pXyn3pF3lM8R5V/cxTbj5HD9/G\nVfKyBDbtgB9TxF00KGu+x1X8Z+rLP3+QsjPNG1gQggL4+C/1E2DUBc7xgQjB3ad1\nl08YuW3e95ORCLp+QCztweq7dp4zBncdDQh/U90bZKuCJ/Fp1U1ervShw3WnWEQt\n8jxwmKy6abaVd38PMV4s/KCHOkdp8Hlf9BRUpJVeEXgSYCfOn8J3/yNTd126/+pZ\n59vPr5KW7ySaNRB6nJHGDn2Z9j8Z3/VyVOEVqQdZe4O/Ui5GjLIAZHYcSNPYeehu\nVsyuLAOQ1xk4meTKCRlb/weWsKh/NEnfVqn3sF/tM+2MR7cwA130A4w=\n-----END CERTIFICATE-----\n",
-                "is_ca": true,
-                "issuer": "OU=Starfield Class 2 Certification Authority,O=Starfield Technologies\\, Inc.,C=US",
-                "not_after": "2034-06-28T17:39:16Z",
-                "not_before": "2009-09-02T00:00:00Z",
-                "public_key_algorithm": "RSA",
-                "serial_number": "12037640545166866303",
-                "sha1_fingerprint": "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
-                "signature_algorithm": "SHA256-RSA",
-                "subject": "CN=Starfield Services Root Certificate Authority - G2,O=Starfield Technologies\\, Inc.,L=Scottsdale,ST=Arizona,C=US",
-                "version": 3
-              },
-              {
-                "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIEkjCCA3qgAwIBAgITBn+USionzfP6wq4rAfkI7rnExjANBgkqhkiG9w0BAQsF\nADCBmDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNj\nb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4x\nOzA5BgNVBAMTMlN0YXJmaWVsZCBTZXJ2aWNlcyBSb290IENlcnRpZmljYXRlIEF1\ndGhvcml0eSAtIEcyMB4XDTE1MDUyNTEyMDAwMFoXDTM3MTIzMTAxMDAwMFowOTEL\nMAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv\nb3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj\nca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM\n9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw\nIFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6\nVOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L\n93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm\njgSubJrIqg0CAwEAAaOCATEwggEtMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/\nBAQDAgGGMB0GA1UdDgQWBBSEGMyFNOy8DJSULghZnMeyEE4KCDAfBgNVHSMEGDAW\ngBScXwDfqgHXMCs4iKK4bUqc8hGRgzB4BggrBgEFBQcBAQRsMGowLgYIKwYBBQUH\nMAGGImh0dHA6Ly9vY3NwLnJvb3RnMi5hbWF6b250cnVzdC5jb20wOAYIKwYBBQUH\nMAKGLGh0dHA6Ly9jcnQucm9vdGcyLmFtYXpvbnRydXN0LmNvbS9yb290ZzIuY2Vy\nMD0GA1UdHwQ2MDQwMqAwoC6GLGh0dHA6Ly9jcmwucm9vdGcyLmFtYXpvbnRydXN0\nLmNvbS9yb290ZzIuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQsF\nAAOCAQEAYjdCXLwQtT6LLOkMm2xF4gcAevnFWAu5CIw+7bMlPLVvUOTNNWqnkzSW\nMiGpSESrnO09tKpzbeR/FoCJbM8oAxiDR3mjEH4wW6w7sGDgd9QIpuEdfF7Au/ma\neyKdpwAJfqxGF4PcnCZXmTA5YpaP7dreqsXMGz7KQ2hsVxa81Q4gLv7/wmpdLqBK\nbRRYh5TmOTFffHPLkIhqhBGWJ6bt2YFGpn6jcgAKUj6DiAdjd4lpFw85hdKrCEVN\n0FE6/V1dN2RMfjCyVSRCnTawXZwXgWHxyvkQAiSr6w10kY17RSlQOYiypok1JR4U\nakcjMS9cmvqtmg5iUaQqqcT5NJ0hGA==\n-----END CERTIFICATE-----\n",
-                "is_ca": true,
-                "issuer": "CN=Starfield Services Root Certificate Authority - G2,O=Starfield Technologies\\, Inc.,L=Scottsdale,ST=Arizona,C=US",
-                "not_after": "2037-12-31T01:00:00Z",
-                "not_before": "2015-05-25T12:00:00Z",
-                "public_key_algorithm": "RSA",
-                "serial_number": "144918191876577076464031512351042010504348870",
-                "sha1_fingerprint": "06b25927c42a721631c1efd9431e648fa62e1e39",
-                "signature_algorithm": "SHA256-RSA",
-                "subject": "CN=Amazon Root CA 1,O=Amazon,C=US",
-                "version": 3
-              },
-              {
-                "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIEXjCCA0agAwIBAgITB3MSTNQG0mfAmRzdKZqfODF5hTANBgkqhkiG9w0BAQsF\nADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6\nb24gUm9vdCBDQSAxMB4XDTIyMDgyMzIyMjYwNFoXDTMwMDgyMzIyMjYwNFowPDEL\nMAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEcMBoGA1UEAxMTQW1hem9uIFJT\nQSAyMDQ4IE0wMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALd/pVko\n8vuM475Tf45HV3BbCl/B9Jy89G1CRkFjcPY06WA9lS+7dWbUA7GtWUKoksr69hKM\nwcMsNpxlw7b3jeXFgxB09/nmalcAWtnLzF+LaDKEA5DQmvKzuh1nfIfqEiKCQSmX\nXh09Xs+dO7cm5qbaL2hhNJCSAejciwcvOFgFNgEMR42wm6KIFHsQW28jhA+1u/M0\np6fVwReuEgZfLfdx82Px0LJck3lST3EB/JfbdsdOzzzg5YkY1dfuqf8y5fUeZ7Cz\nWXbTjujwX/TovmeWKA36VLCz75azW6tDNuDn66FOpADZZ9omVaF6BqNJiLMVl6P3\n/c0OiUMC6Z5OfKcCAwEAAaOCAVowggFWMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYD\nVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNV\nHQ4EFgQUVdkYX9IczAHhWLS+q9lVQgHXLgIwHwYDVR0jBBgwFoAUhBjMhTTsvAyU\nlC4IWZzHshBOCggwewYIKwYBBQUHAQEEbzBtMC8GCCsGAQUFBzABhiNodHRwOi8v\nb2NzcC5yb290Y2ExLmFtYXpvbnRydXN0LmNvbTA6BggrBgEFBQcwAoYuaHR0cDov\nL2NydC5yb290Y2ExLmFtYXpvbnRydXN0LmNvbS9yb290Y2ExLmNlcjA/BgNVHR8E\nODA2MDSgMqAwhi5odHRwOi8vY3JsLnJvb3RjYTEuYW1hem9udHJ1c3QuY29tL3Jv\nb3RjYTEuY3JsMBMGA1UdIAQMMAowCAYGZ4EMAQIBMA0GCSqGSIb3DQEBCwUAA4IB\nAQAGjeWm2cC+3z2MzSCnte46/7JZvj3iQZDY7EvODNdZF41n71Lrk9kbfNwerK0d\nVNzW36Wefr7j7ZSwBVg50W5ay65jNSN74TTQV1yt4WnSbVvN6KlMs1hiyOZdoHKs\nKDV2UGNxbdoBYCQNa2GYF8FQIWLugNp35aSOpMy6cFlymFQomIrnOQHwK1nvVY4q\nxDSJMU/gNJz17D8ArPN3ngnyZ2TwepJ0uBINz3G5te2rdFUF4i4Y3Bb7FUlHDYm4\nu8aIRGpk2ZpfXmxaoxnbIBZRvGLPSUuPwnwoUOMsJ8jirI5vs2dvchPb7MtI1rle\ni02f2ivH2vxkjDLltSpe2fiC\n-----END CERTIFICATE-----\n",
-                "is_ca": true,
-                "issuer": "CN=Amazon Root CA 1,O=Amazon,C=US",
-                "not_after": "2030-08-23T22:26:04Z",
-                "not_before": "2022-08-23T22:26:04Z",
-                "public_key_algorithm": "RSA",
-                "serial_number": "166129356476704345391986644047206454194698629",
-                "sha1_fingerprint": "d9fe0a65fa00cabf61f5120d373a8135e1461f15",
-                "signature_algorithm": "SHA256-RSA",
-                "subject": "CN=Amazon RSA 2048 M03,O=Amazon,C=US",
-                "version": 3
-              },
-              {
-                "cert_pem": "-----BEGIN CERTIFICATE-----\nMIIF5zCCBM+gAwIBAgIQB8/B5LYdWaaSLNb9DZLprTANBgkqhkiG9w0BAQsFADA8\nMQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRwwGgYDVQQDExNBbWF6b24g\nUlNBIDIwNDggTTAzMB4XDTI1MDIyNjAwMDAwMFoXDTI2MDMyNzIzNTk1OVowKDEm\nMCQGA1UEAwwdKi5la3MudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20wggEiMA0GCSqG\nSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCoHWcgrIv/D6CxSXSxAq0GuOPoCJqnVz6U\nMhp1YLE9OZs3jH8EfYlNpGtqOtLa1vZb8Lp4CZdATHTj1SoK01MwmXXIDm2Jj+Km\niQvZ0BBe5xroDWvf3r/LWG/WMkRtR4F+qPb9pVYlM9N3WZdSAKfTQTowGxebugLc\nM/+ZLvAxxdtaXK+LID6JRKRa2BIRHcfILiNJo7vIS/I+DOqXn9Rb0VFnkpYpGE+k\nm47kVkFFsToior7zlAwPv6VWsm+zZV9zNnCpu9FpJ3vkZE9OGHS6aChtSya2Qpyr\njyF98KIFTQ+FKtDZHf9XLHmV5v/IP2bWk7lzmPYW4PwcPhDUmC9PAgMBAAGjggL3\nMIIC8zAfBgNVHSMEGDAWgBRV2Rhf0hzMAeFYtL6r2VVCAdcuAjAdBgNVHQ4EFgQU\n6mCbzMC1FaJuw7tKpv7muQZDZrowKAYDVR0RBCEwH4IdKi5la3MudXMtZWFzdC0x\nLmFtYXpvbmF3cy5jb20wEwYDVR0gBAwwCjAIBgZngQwBAgEwDgYDVR0PAQH/BAQD\nAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjA7BgNVHR8ENDAyMDCg\nLqAshipodHRwOi8vY3JsLnIybTAzLmFtYXpvbnRydXN0LmNvbS9yMm0wMy5jcmww\ndQYIKwYBBQUHAQEEaTBnMC0GCCsGAQUFBzABhiFodHRwOi8vb2NzcC5yMm0wMy5h\nbWF6b250cnVzdC5jb20wNgYIKwYBBQUHMAKGKmh0dHA6Ly9jcnQucjJtMDMuYW1h\nem9udHJ1c3QuY29tL3IybTAzLmNlcjAMBgNVHRMBAf8EAjAAMIIBfwYKKwYBBAHW\neQIEAgSCAW8EggFrAWkAdgAOV5S8866pPjMbLJkHs/eQ35vCPXEyJd0hqSWsYcVO\nIQAAAZVBW4SGAAAEAwBHMEUCIQC+CghIdRNpEnK+JGxaeHOel/pYJSUsog1eklre\nLGmoTwIgAj1vm4d6u/93S7GVfw7qotajiMfgHeEf7lANQf0mxf4AdgBkEcRspBLs\np4kcogIuALyrTygH1B41J6vq/tUDyX3N8AAAAZVBW4Q1AAAEAwBHMEUCIAYyeDIv\nJD1IhUkb1E59cbCwTcAYChrSArEZOOAib3dJAiEAix8XjjqXhMNuji/u2fzLxeZ7\nc5PCtDHWx3Ky7QYBfCUAdwBJnJtp3h187Pw23s2HZKa4W68Kh4AZ0VVS++nrKd34\nwwAAAZVBW4RMAAAEAwBIMEYCIQCsj67XcK6jtETNJEPTYPaFqJOMlNtM0TeJwGhm\nBc81sQIhAJoirhaQzC4ydAzLvjpVqKYyuqLktiHkTqFq8IGxBAkIMA0GCSqGSIb3\nDQEBCwUAA4IBAQAjjE2au5fdV/DrlD3e5zZ5hTB4CicIARTWvJQ6EsQm/vbXPoUY\nSHRZkOodq0AJWEC/RImGu8bnVY8RzGsELkMzI4A8UxdlH2YGP8obg6MfP6yGZaHM\nnS4wLX05EnmrABaoRB/apt7tE4w+yRa7QoxUgiTPpFzaQVv1mTcGaWMG55U8tPg7\nLXm539O4OBukbP8HNvjBZ8+N0RYrtG0u0M4FMX1hMKG0bkjJiU6MVZfGJWcgp7I4\nbd5cj5SfE1EHL70P7ELaocXjnWKbys9Mc870aoRXVfAC4bZWU6F9Ke3O7ioXXd5L\n0mKQwrjkiglpYaXc247Qi8IUCdk6s13xHJ4e\n-----END CERTIFICATE-----\n",
-                "is_ca": false,
-                "issuer": "CN=Amazon RSA 2048 M03,O=Amazon,C=US",
-                "not_after": "2026-03-27T23:59:59Z",
-                "not_before": "2025-02-26T00:00:00Z",
-                "public_key_algorithm": "RSA",
-                "serial_number": "10383334045647432453656403708671617453",
-                "sha1_fingerprint": "63462dda480d8b900e0a7dbfaf6238a62ba4fce0",
-                "signature_algorithm": "SHA256-RSA",
-                "subject": "CN=*.eks.us-east-1.amazonaws.com",
-                "version": 3
-              }
-            ],
-            "content": null,
-            "id": "922877a0975ad078a65b8ff11ebc47b8311945c7",
-            "url": "https://oidc.eks.us-east-1.amazonaws.com/id/FBEDC358103BF81590987173813C5E10",
-            "verify_chain": true
-          },
-          "sensitive_attributes": [],
-          "identity_schema_version": 0
-        }
-      ]
-    },
-    {
-      "module": "module.eks.module.eks",
       "mode": "managed",
       "type": "aws_cloudwatch_log_group",
       "name": "this",
@@ -466,46 +383,6 @@
     {
       "module": "module.eks.module.eks",
       "mode": "managed",
-      "type": "aws_ec2_tag",
-      "name": "cluster_primary_security_group",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
-      "type": "aws_eks_access_entry",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
-      "type": "aws_eks_access_policy_association",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
-      "type": "aws_eks_addon",
-      "name": "before_compute",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
-      "type": "aws_eks_addon",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
       "type": "aws_eks_cluster",
       "name": "this",
       "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
@@ -650,14 +527,6 @@
           "create_before_destroy": true
         }
       ]
-    },
-    {
-      "module": "module.eks.module.eks",
-      "mode": "managed",
-      "type": "aws_eks_identity_provider_config",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
     },
     {
       "module": "module.eks.module.eks",
@@ -1005,7 +874,7 @@
             "ingress": [
               {
                 "cidr_blocks": [
-                  "0.0.0.0/0"
+                  "23.93.84.244/32"
                 ],
                 "description": "Allow ingress to EKS control plane from specified CIDRs",
                 "from_port": 443,
@@ -1726,14 +1595,6 @@
           "identity_schema_version": 0
         }
       ]
-    },
-    {
-      "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"]",
-      "mode": "data",
-      "type": "aws_ssm_parameter",
-      "name": "ami",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
     },
     {
       "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"]",
@@ -1746,14 +1607,6 @@
     {
       "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"]",
       "mode": "managed",
-      "type": "aws_autoscaling_schedule",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"]",
-      "mode": "managed",
       "type": "aws_eks_node_group",
       "name": "this",
       "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
@@ -2136,22 +1989,6 @@
       ]
     },
     {
-      "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"]",
-      "mode": "managed",
-      "type": "aws_placement_group",
-      "name": "this",
-      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
-      "instances": []
-    },
-    {
-      "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"].module.user_data",
-      "mode": "data",
-      "type": "cloudinit_config",
-      "name": "al2023_eks_managed_node_group",
-      "provider": "provider[\"registry.terraform.io/hashicorp/cloudinit\"]",
-      "instances": []
-    },
-    {
       "module": "module.eks.module.eks.module.eks_managed_node_group[\"default\"].module.user_data",
       "mode": "data",
       "type": "cloudinit_config",
@@ -2760,7 +2597,7 @@
             "ingress": [
               {
                 "cidr_blocks": [
-                  "0.0.0.0/0"
+                  "23.93.84.244/32"
                 ],
                 "description": "Allow app traffic from specified CIDRs",
                 "from_port": 8080,
@@ -2837,8 +2674,8 @@
             "description": "Allow ingress to EKS control plane from specified CIDRs",
             "from_port": 443,
             "id": "sgrule-3234424322",
-            "ipv6_cidr_blocks": [],
-            "prefix_list_ids": [],
+            "ipv6_cidr_blocks": null,
+            "prefix_list_ids": null,
             "protocol": "tcp",
             "security_group_id": "sg-0c5845ab7f0ddd8f8",
             "security_group_rule_id": "sgr-04675cd42b9566795",
@@ -2850,7 +2687,11 @@
           },
           "sensitive_attributes": [],
           "identity_schema_version": 0,
-          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjozMDAwMDAwMDAwMDB9LCJzY2hlbWFfdmVyc2lvbiI6IjIifQ=="
+          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjozMDAwMDAwMDAwMDB9LCJzY2hlbWFfdmVyc2lvbiI6IjIifQ==",
+          "dependencies": [
+            "module.eks.module.eks.aws_security_group.cluster",
+            "module.vpc.module.vpc.aws_vpc.this"
+          ]
         }
       ]
     },
@@ -4609,5 +4450,29 @@
       "instances": []
     }
   ],
-  "check_results": null
+  "check_results": [
+    {
+      "object_kind": "resource",
+      "config_addr": "module.eks.module.eks.module.self_managed_node_group.module.user_data.null_resource.validate_cluster_service_cidr",
+      "status": "pass",
+      "objects": null
+    },
+    {
+      "object_kind": "resource",
+      "config_addr": "module.eks.module.eks.module.eks_managed_node_group.module.user_data.null_resource.validate_cluster_service_cidr",
+      "status": "unknown",
+      "objects": [
+        {
+          "object_addr": "module.eks.module.eks.module.eks_managed_node_group[\"default\"].module.user_data.null_resource.validate_cluster_service_cidr",
+          "status": "unknown"
+        }
+      ]
+    },
+    {
+      "object_kind": "var",
+      "config_addr": "module.eks.module.eks.module.self_managed_node_group.var.platform",
+      "status": "pass",
+      "objects": null
+    }
+  ]
 }
tim@Tims-MBP ecommerce-k8s % terraform state pull > temp.tfstate
tim@Tims-MBP ecommerce-k8s % terraform state list -state=temp.tfstate | grep eks_control_plane_ingress
module.networking.aws_security_group_rule.eks_control_plane_ingress
tim@Tims-MBP ecommerce-k8s % cp temp.tfstate temp.tfstate.backup
tim@Tims-MBP ecommerce-k8s % cp current.tfstate current.tfstate.backup
tim@Tims-MBP ecommerce-k8s % cp errored.tfstate errored.tfstate.backup
tim@Tims-MBP ecommerce-k8s % ls
README.ecommerce.txt	docs			errored.tfstate.json	main.tf			temp.tfstate		variables.tf
backend.hcl		ecommerce-app		iam-policy.json		modules			temp.tfstate.backup
current.tfstate		errored.tfstate		kubernetes		old			terraform.tfvars
current.tfstate.backup	errored.tfstate.backup	logs			outputs.tf		tfplan
tim@Tims-MBP ecommerce-k8s % ls modules/eks
main.tf		outputs.tf	variables.tf
tim@Tims-MBP ecommerce-k8s % ls modules/eks/main.tf 
modules/eks/main.tf
tim@Tims-MBP ecommerce-k8s % vi !$
vi modules/eks/main.tf
tim@Tims-MBP ecommerce-k8s % cat main.tf 
# main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.94.1"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
  }

  backend "s3" {
    # Configuration loaded from backend.hcl
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  region              = var.region
  vpc_name            = "ecommerce-vpc"
  vpc_cidr            = "10.0.0.0/16"
  azs                 = ["${var.region}a", "${var.region}b"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  cluster_name        = "ecommerce-cluster"
}

module "eks" {
  source = "./modules/eks"

  cluster_name                     = "ecommerce-cluster"
  cluster_version                  = "1.29"
  vpc_id                           = module.vpc.vpc_id
  subnet_ids                       = module.vpc.private_subnets
  cluster_endpoint_public_access   = true
  cluster_endpoint_private_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Adjusted for testing
  cluster_enabled_log_types        = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  node_groups = {
    default = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
    }
  }
}

module "networking" {
  source = "./modules/networking"

  region                           = var.region
  vpc_id                           = module.vpc.vpc_id
  cluster_name                     = module.eks.cluster_name
  cluster_security_group_id        = module.eks.cluster_security_group_id
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Adjusted for testing
  private_route_table_ids          = module.vpc.private_route_table_ids
}

module "iam" {
  source = "./modules/iam"

  cluster_name         = module.eks.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  cluster_security_group_id = module.eks.cluster_security_group_id
  node_group_role_name = module.eks.node_group_role_name
}

module "s3" {
  source = "./modules/s3"

  bucket_name = "blued-ecommerce-app-us-east-1-prod"
  cluster_name = module.eks.cluster_name
}
tim@Tims-MBP ecommerce-k8s % find modules/eks
modules/eks
modules/eks/outputs.tf
modules/eks/main.tf
modules/eks/variables.tf
tim@Tims-MBP ecommerce-k8s % cat modules/eks/main.tf 
# modules/eks/main.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types

  eks_managed_node_groups = var.node_groups
}
tim@Tims-MBP ecommerce-k8s % cat modules/eks/variables.tf 
# modules/eks/variables.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the cluster endpoint publicly"
  type        = list(string)
}

variable "cluster_enabled_log_types" {
  description = "List of enabled log types for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Configuration for EKS managed node groups"
  type        = map(any)
}
tim@Tims-MBP ecommerce-k8s % cat modules/eks/outputs.tf 
# modules/eks/outputs.tf
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_group_role_name" {
  description = "IAM role name for the EKS node group"
  value       = module.eks.eks_managed_node_groups["default"].iam_role_name
}
tim@Tims-MBP ecommerce-k8s % terraform state show 'module.eks.module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]'
# module.eks.module.eks.module.eks_managed_node_group["default"].aws_eks_node_group.this[0]:
resource "aws_eks_node_group" "this" {
    ami_type               = "AL2_x86_64"
    arn                    = "arn:aws:eks:us-east-1:084375569056:nodegroup/ecommerce-cluster/default-20250610194844026900000015/40cbadb1-a6ee-879b-b11e-9eff2ba1c26f"
    capacity_type          = "ON_DEMAND"
    cluster_name           = "ecommerce-cluster"
    disk_size              = 0
    id                     = "ecommerce-cluster:default-20250610194844026900000015"
    instance_types         = [
        "t3.medium",
    ]
    labels                 = {}
    node_group_name        = "default-20250610194844026900000015"
    node_group_name_prefix = "default-"
    node_role_arn          = "arn:aws:iam::084375569056:role/default-eks-node-group-20250610193844994300000001"
    release_version        = "1.29.15-20250519"
    resources              = [
        {
            autoscaling_groups              = [
                {
                    name = "eks-default-20250610194844026900000015-40cbadb1-a6ee-879b-b11e-9eff2ba1c26f"
                },
            ]
            remote_access_security_group_id = null
        },
    ]
    status                 = "ACTIVE"
    subnet_ids             = [
        "subnet-014450521809bc8b9",
        "subnet-0e1ff6a65bda1e4f8",
    ]
    tags                   = {
        "Name" = "default"
    }
    tags_all               = {
        "Name" = "default"
    }
    version                = "1.29"

    launch_template {
        id      = "lt-0bede0939be27d975"
        name    = "default-20250610194837988700000013"
        version = "1"
    }

    scaling_config {
        desired_size = 2
        max_size     = 3
        min_size     = 2
    }

    timeouts {}

    update_config {
        max_unavailable            = 0
        max_unavailable_percentage = 33
    }
}
tim@Tims-MBP ecommerce-k8s % 

tim@Tims-MBP ecommerce-k8s % terraform state pull > temp.tfstate
tim@Tims-MBP ecommerce-k8s % terraform state list -state=temp.tfstate | grep eks_control_plane_ingress
module.networking.aws_security_group_rule.eks_control_plane_ingress
tim@Tims-MBP ecommerce-k8s % terraform state show 'module.networking.aws_security_group_rule.eks_control_plane_ingress'
# module.networking.aws_security_group_rule.eks_control_plane_ingress:
resource "aws_security_group_rule" "eks_control_plane_ingress" {
    cidr_blocks            = [
        "0.0.0.0/0",
    ]
    description            = "Allow ingress to EKS control plane from specified CIDRs"
    from_port              = 443
    id                     = "sgrule-3234424322"
    ipv6_cidr_blocks       = []
    prefix_list_ids        = []
    protocol               = "tcp"
    security_group_id      = "sg-0c5845ab7f0ddd8f8"
    security_group_rule_id = "sgr-04675cd42b9566795"
    self                   = false
    to_port                = 443
    type                   = "ingress"
}
tim@Tims-MBP ecommerce-k8s % cp temp.tfstate temp.tfstate.backup
tim@Tims-MBP ecommerce-k8s % cp current.tfstate current.tfstate.backup
tim@Tims-MBP ecommerce-k8s % cp errored.tfstate errored.tfstate.backup
tim@Tims-MBP ecommerce-k8s % ls -R modules/eks/
main.tf		outputs.tf	variables.tf
tim@Tims-MBP ecommerce-k8s % cat modules/eks/main.tf 
# modules/eks/main.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types            = var.cluster_enabled_log_types

  eks_managed_node_groups = var.node_groups
}
tim@Tims-MBP ecommerce-k8s % cat modules/eks/variables.tf 
# modules/eks/variables.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the cluster endpoint publicly"
  type        = list(string)
}

variable "cluster_enabled_log_types" {
  description = "List of enabled log types for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Configuration for EKS managed node groups"
  type        = map(any)
}
tim@Tims-MBP ecommerce-k8s % cat modules/eks/outputs.tf 
# modules/eks/outputs.tf
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_group_role_name" {
  description = "IAM role name for the EKS node group"
  value       = module.eks.eks_managed_node_groups["default"].iam_role_name
}
