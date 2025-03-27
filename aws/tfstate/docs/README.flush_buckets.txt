(py3) tim@Tims-MBP single_instance % aws s3 ls s3://bluedragon-log-bucket-qt386gvs --recursive
2025-03-25 10:24:29      11867 logs/2025-03-25-17-24-28-495BBB27756E4E79
2025-03-25 10:30:30       2075 logs/2025-03-25-17-30-29-9781879F7F5542A1
2025-03-25 10:47:09      11151 logs/2025-03-25-17-47-08-2C1B2E8B1BB8A559
2025-03-25 11:17:01      13299 logs/2025-03-25-18-17-00-EC4401657D9D61A7
2025-03-25 11:25:42       1318 logs/2025-03-25-18-25-41-A9B98BEB1B22BD54
2025-03-25 14:19:36      11316 logs/2025-03-25-21-19-35-0610B824F07487CD
2025-03-25 14:27:17      13956 logs/2025-03-25-21-27-16-FE4413D558326C88
2025-03-25 14:40:28       2636 logs/2025-03-25-21-40-27-83AD749A4C9F63CA
2025-03-25 14:42:54       4619 logs/2025-03-25-21-42-53-6F7950C18F2564BC
2025-03-25 15:16:51      12553 logs/2025-03-25-22-16-50-E3950CA00A92A530
2025-03-25 15:35:01      11849 logs/2025-03-25-22-35-00-BA9009F6A0B24FB1
2025-03-25 15:43:26       8313 logs/2025-03-25-22-43-25-38365BE50325F129
2025-03-25 15:46:35        693 logs/2025-03-25-22-46-34-B415FE97732A41EB
2025-03-25 16:25:51      16223 logs/2025-03-25-23-25-50-77C754372A4043DB
2025-03-25 18:40:33      15936 logs/2025-03-26-01-40-32-14F71220D23A4EB0
2025-03-25 18:43:30      15935 logs/2025-03-26-01-43-29-6BFBA7874BAED7A8
2025-03-25 19:18:05      16703 logs/2025-03-26-02-18-04-309756F1354B2A89
2025-03-25 19:20:48      11865 logs/2025-03-26-02-20-47-83773D0FA769E28F
2025-03-25 19:31:31       3457 logs/2025-03-26-02-31-30-DC4BFF289F97312D
2025-03-25 19:40:55        693 logs/2025-03-26-02-40-54-F417EC2BEDD956E7
2025-03-25 19:43:41        692 logs/2025-03-26-02-43-40-50E598A5905BA6EE
2025-03-26 13:22:45       3959 logs/2025-03-26-20-22-44-4648C192D8343DB6
2025-03-26 13:24:34      11976 logs/2025-03-26-20-24-33-63F2D017A6871129
2025-03-26 13:29:55       3959 logs/2025-03-26-20-29-54-E43FA85A68F8CDB4
2025-03-26 13:30:24      11976 logs/2025-03-26-20-30-23-DE473F3BB7EDEE68
2025-03-26 13:32:46      11320 logs/2025-03-26-20-32-45-EFFE6E162E0A3454
2025-03-26 13:43:01       3956 logs/2025-03-26-20-43-00-8A6445CEA517F71C
2025-03-26 13:46:08        664 logs/2025-03-26-20-46-07-5672AF46E72079C7
2025-03-26 14:45:04      15936 logs/2025-03-26-21-45-02-943D0E3183B2FAF9
(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-log-bucket-qt386gvs > versions.txt
(py3) tim@Tims-MBP single_instance % wc -l versions.txt 
     470 versions.txt
(py3) tim@Tims-MBP single_instance % cat versions.txt 
{
    "Versions": [
        {
            "ETag": ""3a5b2e5aaa513228209e93c78baa5c5b"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11867,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-17-24-28-495BBB27756E4E79",
            "VersionId": "1YSE2makdgl7EqWQhKz7fvz4PAKlFGO4",
            "IsLatest": true,
            "LastModified": "2025-03-25T17:24:29+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""8c20d5d7530d55f81a4d772dd2f73758"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 2075,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-17-30-29-9781879F7F5542A1",
            "VersionId": "kQv9KhmlAFsrZ_jOncVjdFRWA6xJ4nV3",
            "IsLatest": true,
            "LastModified": "2025-03-25T17:30:30+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""0c1fbd11e2df981f947ae20d03ef25e1"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11151,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-17-47-08-2C1B2E8B1BB8A559",
            "VersionId": "2cYlSEIbKsIVsBde51f4LH3DmZsLCqd2",
            "IsLatest": true,
            "LastModified": "2025-03-25T17:47:09+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""74bc7ea779ff35a6be0d9a212eac55ba"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 13299,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-18-17-00-EC4401657D9D61A7",
            "VersionId": "0c9wpGkbEl8zf.qulwnnpST.Ov5xqcxI",
            "IsLatest": true,
            "LastModified": "2025-03-25T18:17:01+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""45077b7404192dd62c83737a32a0bd4d"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 1318,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-18-25-41-A9B98BEB1B22BD54",
            "VersionId": "Y4jx_4TTqHBt8uwaUOQc8uNQKNX8x0lS",
            "IsLatest": true,
            "LastModified": "2025-03-25T18:25:42+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""0b5be14945fc31e92308a827e1dd2220"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11316,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-21-19-35-0610B824F07487CD",
            "VersionId": "WTpw6Nbd6YDPqujkDFBoHmK54TRl8aBR",
            "IsLatest": true,
            "LastModified": "2025-03-25T21:19:36+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""c3acc7fc0acb2b5d00e677536f11cc38"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 13956,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-21-27-16-FE4413D558326C88",
            "VersionId": "xJrCsEOJn_ZDe8iFtvu74XXOdENVNs5W",
            "IsLatest": true,
            "LastModified": "2025-03-25T21:27:17+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""5468446d98efd05c987d1c9726f0e652"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 2636,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-21-40-27-83AD749A4C9F63CA",
            "VersionId": "VEMOhvGoJCiV8rvFsZwknxQHqT_zQmGK",
            "IsLatest": true,
            "LastModified": "2025-03-25T21:40:28+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""ea83b09323bcdf82e5539429e8c33fed"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 4619,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-21-42-53-6F7950C18F2564BC",
            "VersionId": "EA.8SAH2NGwGhjnh_rh8R4kFzaxPk5ae",
            "IsLatest": true,
            "LastModified": "2025-03-25T21:42:54+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""7a4ea445cb8d79b6b73bc3857476be2a"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 12553,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-22-16-50-E3950CA00A92A530",
            "VersionId": "2R4It7wADcBBURjr1zORrtmydzYDVoa8",
            "IsLatest": true,
            "LastModified": "2025-03-25T22:16:51+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""186d70da1100a75b73de0f2609829283"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11849,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-22-35-00-BA9009F6A0B24FB1",
            "VersionId": "jxq0H9wiHaEvcvaA45bwd0qGGOCa5Sp_",
            "IsLatest": true,
            "LastModified": "2025-03-25T22:35:01+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""418f27edfe72900712d2465e7e9a5b28"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 8313,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-22-43-25-38365BE50325F129",
            "VersionId": "2aX3y9aLRfT9DIx7lFOnNqZhvnngm79O",
            "IsLatest": true,
            "LastModified": "2025-03-25T22:43:26+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""815d30c18c22108d9139080e68c40758"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 693,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-22-46-34-B415FE97732A41EB",
            "VersionId": "HKf1L7LuyGZ0UOop55cd9_FtQ3sp.dnc",
            "IsLatest": true,
            "LastModified": "2025-03-25T22:46:35+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""0858fe338803e590eab5b4bfa1c3bcdd"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 16223,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-25-23-25-50-77C754372A4043DB",
            "VersionId": "GprNDX1OrzOmfj6O7Xw03IipZDm9mrzE",
            "IsLatest": true,
            "LastModified": "2025-03-25T23:25:51+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""0cde29954dbfad71b17e0a6053648ebb"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 15936,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-01-40-32-14F71220D23A4EB0",
            "VersionId": "4amGTRzBO3.ye4izrmE.ysq0BsboKrO8",
            "IsLatest": true,
            "LastModified": "2025-03-26T01:40:33+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""412aabe99d3b0c4b37a5c92eb22eb7bc"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 15935,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-01-43-29-6BFBA7874BAED7A8",
            "VersionId": "FDquPcxdeejDf.wLG7VX2yoqtL4wSBn1",
            "IsLatest": true,
            "LastModified": "2025-03-26T01:43:30+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""7acd9b2d0e888fbf694861cad762d9dc"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 16703,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-02-18-04-309756F1354B2A89",
            "VersionId": "PCshfbZC5X8YxREEY02gTp3NVInLaiAi",
            "IsLatest": true,
            "LastModified": "2025-03-26T02:18:05+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""24302a242d1f565b61f4aee92d6c5795"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11865,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-02-20-47-83773D0FA769E28F",
            "VersionId": "KQQb1a.JqJpqZTQcuOVAaL4jgtkwyj4P",
            "IsLatest": true,
            "LastModified": "2025-03-26T02:20:48+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""07d5a686fda0308856d10546128a7679"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 3457,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-02-31-30-DC4BFF289F97312D",
            "VersionId": "NDO6eSCs2N8Pw4ibRdoO3LvbTPTBUyJJ",
            "IsLatest": true,
            "LastModified": "2025-03-26T02:31:31+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""68771db79455fb5fd1d9363e1ca4ec8d"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 693,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-02-40-54-F417EC2BEDD956E7",
            "VersionId": "3Q5KbBj0HoUTXlkNfK9xLZJw9aW3buK5",
            "IsLatest": true,
            "LastModified": "2025-03-26T02:40:55+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""2b2587bc79f3664a83ae22a80aafc014"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 692,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-02-43-40-50E598A5905BA6EE",
            "VersionId": "l9f0qIrfHHBaduevmvxr15vXdp30pctf",
            "IsLatest": true,
            "LastModified": "2025-03-26T02:43:41+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""dd8f9327e972ee92c6378444cc661f29"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 3959,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-22-44-4648C192D8343DB6",
            "VersionId": "VHENuKNdfqJWlRod3BMw.6WIK6t4FTwi",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:22:45+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""dcf85240e6e36e2b6265a92891199eb8"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11976,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-24-33-63F2D017A6871129",
            "VersionId": "wQZbw1jhCUeaqrfZi25s9tLiZ_bFTtv_",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:24:34+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""368404ff6aae119cd489fee2cd4974e2"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 3959,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-29-54-E43FA85A68F8CDB4",
            "VersionId": "0MYEapFz6s_EniEXzlZlJAhG0IoB0BFs",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:29:55+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""60cd3107565adf9b8b637079ed164078"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11976,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-30-23-DE473F3BB7EDEE68",
            "VersionId": "gMjbAzpjWeDYzC0DJCmwg6sk2k64bjl3",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:30:24+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""c0b68d1ccd7ba2dfdc17d7f72a81338d"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 11320,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-32-45-EFFE6E162E0A3454",
            "VersionId": "6A1p7zgorZN1wxEsTVELptw1y2hFSU8E",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:32:46+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""fd80ba99aab55b2f74f2ee307fc0c979"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 3956,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-43-00-8A6445CEA517F71C",
            "VersionId": "qtG0noYMujIWKRquJYs.KREZAnJNzina",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:43:01+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""73b6963b681ba05eac3d0724fd57183a"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 664,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-20-46-07-5672AF46E72079C7",
            "VersionId": "4MMZJc3ZskLp.2qBDp7tcLy6qpmKwBjF",
            "IsLatest": true,
            "LastModified": "2025-03-26T20:46:08+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        },
        {
            "ETag": ""75f5820fd03f31f706fb8b961c48d981"",
            "ChecksumAlgorithm": [
                "CRC64NVME"
            ],
            "Size": 15936,
            "StorageClass": "STANDARD",
            "Key": "logs/2025-03-26-21-45-02-943D0E3183B2FAF9",
            "VersionId": "crI32OVu4ucT3vLjlbE1le6F.LIjQPp2",
            "IsLatest": true,
            "LastModified": "2025-03-26T21:45:04+00:00",
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            }
        }
    ],
    "RequestCharged": null,
    "Prefix": ""
}
(py3) tim@Tims-MBP single_instance %


(py3) tim@Tims-MBP single_instance % aws s3api delete-objects --bucket bluedragon-log-bucket-qt386gvs --delete "$(aws s3api list-object-versions --bucket bluedragon-log-bucket-qt386gvs --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
{
    "Deleted": [
        {
            "Key": "logs/2025-03-26-02-18-04-309756F1354B2A89",
            "VersionId": "PCshfbZC5X8YxREEY02gTp3NVInLaiAi"
        },
        {
            "Key": "logs/2025-03-26-02-43-40-50E598A5905BA6EE",
            "VersionId": "l9f0qIrfHHBaduevmvxr15vXdp30pctf"
        },
        {
            "Key": "logs/2025-03-26-20-30-23-DE473F3BB7EDEE68",
            "VersionId": "gMjbAzpjWeDYzC0DJCmwg6sk2k64bjl3"
        },
        {
            "Key": "logs/2025-03-26-20-32-45-EFFE6E162E0A3454",
            "VersionId": "6A1p7zgorZN1wxEsTVELptw1y2hFSU8E"
        },
        {
            "Key": "logs/2025-03-26-20-46-07-5672AF46E72079C7",
            "VersionId": "4MMZJc3ZskLp.2qBDp7tcLy6qpmKwBjF"
        },
        {
            "Key": "logs/2025-03-26-21-45-02-943D0E3183B2FAF9",
            "VersionId": "crI32OVu4ucT3vLjlbE1le6F.LIjQPp2"
        },
        {
            "Key": "logs/2025-03-25-21-19-35-0610B824F07487CD",
            "VersionId": "WTpw6Nbd6YDPqujkDFBoHmK54TRl8aBR"
        },
        {
            "Key": "logs/2025-03-26-20-43-00-8A6445CEA517F71C",
            "VersionId": "qtG0noYMujIWKRquJYs.KREZAnJNzina"
        },
        {
            "Key": "logs/2025-03-25-18-17-00-EC4401657D9D61A7",
            "VersionId": "0c9wpGkbEl8zf.qulwnnpST.Ov5xqcxI"
        },
        {
            "Key": "logs/2025-03-25-21-27-16-FE4413D558326C88",
            "VersionId": "xJrCsEOJn_ZDe8iFtvu74XXOdENVNs5W"
        },
        {
            "Key": "logs/2025-03-25-17-47-08-2C1B2E8B1BB8A559",
            "VersionId": "2cYlSEIbKsIVsBde51f4LH3DmZsLCqd2"
        },
        {
            "Key": "logs/2025-03-25-22-43-25-38365BE50325F129",
            "VersionId": "2aX3y9aLRfT9DIx7lFOnNqZhvnngm79O"
        },
        {
            "Key": "logs/2025-03-25-18-25-41-A9B98BEB1B22BD54",
            "VersionId": "Y4jx_4TTqHBt8uwaUOQc8uNQKNX8x0lS"
        },
        {
            "Key": "logs/2025-03-26-02-31-30-DC4BFF289F97312D",
            "VersionId": "NDO6eSCs2N8Pw4ibRdoO3LvbTPTBUyJJ"
        },
        {
            "Key": "logs/2025-03-26-01-43-29-6BFBA7874BAED7A8",
            "VersionId": "FDquPcxdeejDf.wLG7VX2yoqtL4wSBn1"
        },
        {
            "Key": "logs/2025-03-25-23-25-50-77C754372A4043DB",
            "VersionId": "GprNDX1OrzOmfj6O7Xw03IipZDm9mrzE"
        },
        {
            "Key": "logs/2025-03-26-02-20-47-83773D0FA769E28F",
            "VersionId": "KQQb1a.JqJpqZTQcuOVAaL4jgtkwyj4P"
        },
        {
            "Key": "logs/2025-03-26-02-40-54-F417EC2BEDD956E7",
            "VersionId": "3Q5KbBj0HoUTXlkNfK9xLZJw9aW3buK5"
        },
        {
            "Key": "logs/2025-03-26-20-29-54-E43FA85A68F8CDB4",
            "VersionId": "0MYEapFz6s_EniEXzlZlJAhG0IoB0BFs"
        },
        {
            "Key": "logs/2025-03-25-22-46-34-B415FE97732A41EB",
            "VersionId": "HKf1L7LuyGZ0UOop55cd9_FtQ3sp.dnc"
        },
        {
            "Key": "logs/2025-03-25-22-35-00-BA9009F6A0B24FB1",
            "VersionId": "jxq0H9wiHaEvcvaA45bwd0qGGOCa5Sp_"
        },
        {
            "Key": "logs/2025-03-25-22-16-50-E3950CA00A92A530",
            "VersionId": "2R4It7wADcBBURjr1zORrtmydzYDVoa8"
        },
        {
            "Key": "logs/2025-03-26-01-40-32-14F71220D23A4EB0",
            "VersionId": "4amGTRzBO3.ye4izrmE.ysq0BsboKrO8"
        },
        {
            "Key": "logs/2025-03-26-20-22-44-4648C192D8343DB6",
            "VersionId": "VHENuKNdfqJWlRod3BMw.6WIK6t4FTwi"
        },
        {
            "Key": "logs/2025-03-25-21-40-27-83AD749A4C9F63CA",
            "VersionId": "VEMOhvGoJCiV8rvFsZwknxQHqT_zQmGK"
        },
        {
            "Key": "logs/2025-03-25-21-42-53-6F7950C18F2564BC",
            "VersionId": "EA.8SAH2NGwGhjnh_rh8R4kFzaxPk5ae"
        },
        {
            "Key": "logs/2025-03-26-20-24-33-63F2D017A6871129",
            "VersionId": "wQZbw1jhCUeaqrfZi25s9tLiZ_bFTtv_"
        },
        {
            "Key": "logs/2025-03-25-17-24-28-495BBB27756E4E79",
            "VersionId": "1YSE2makdgl7EqWQhKz7fvz4PAKlFGO4"
        },
        {
            "Key": "logs/2025-03-25-17-30-29-9781879F7F5542A1",
            "VersionId": "kQv9KhmlAFsrZ_jOncVjdFRWA6xJ4nV3"
        }
    ]
}
(py3) tim@Tims-MBP single_instance % which jq
/usr/local/bin/jq
(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-log-bucket-qt386gvs
{
    "RequestCharged": null,
    "Prefix": ""
}

(py3) tim@Tims-MBP single_instance % terraform destroy
random_string.suffix: Refreshing state... [id=qt386gvs]
data.aws_caller_identity.current: Reading...
module.compute.data.aws_ami.ubuntu: Reading...
module.storage.aws_s3_bucket.log_bucket: Refreshing state... [id=bluedragon-log-bucket-qt386gvs]
module.compute.data.aws_ami.ubuntu: Read complete after 0s [id=ami-0347e16ae916f31a9]
data.aws_caller_identity.current: Read complete after 0s [id=084375569056]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # random_string.suffix will be destroyed
  - resource "random_string" "suffix" {
      - id          = "qt386gvs" -> null
      - length      = 8 -> null
      - lower       = true -> null
      - min_lower   = 0 -> null
      - min_numeric = 0 -> null
      - min_special = 0 -> null
      - min_upper   = 0 -> null
      - number      = true -> null
      - numeric     = true -> null
      - result      = "qt386gvs" -> null
      - special     = false -> null
      - upper       = false -> null
    }

  # module.storage.aws_s3_bucket.log_bucket will be destroyed
  - resource "aws_s3_bucket" "log_bucket" {
      - arn                         = "arn:aws:s3:::bluedragon-log-bucket-qt386gvs" -> null
      - bucket                      = "bluedragon-log-bucket-qt386gvs" -> null
      - bucket_domain_name          = "bluedragon-log-bucket-qt386gvs.s3.amazonaws.com" -> null
      - bucket_regional_domain_name = "bluedragon-log-bucket-qt386gvs.s3.us-west-1.amazonaws.com" -> null
      - force_destroy               = false -> null
      - hosted_zone_id              = "Z2F56UZL2M1ACD" -> null
      - id                          = "bluedragon-log-bucket-qt386gvs" -> null
      - object_lock_enabled         = false -> null
      - region                      = "us-west-1" -> null
      - request_payer               = "BucketOwner" -> null
      - tags                        = {
          - "Name" = "bluedragon-log-bucket"
        } -> null
      - tags_all                    = {
          - "Name" = "bluedragon-log-bucket"
        } -> null
        # (3 unchanged attributes hidden)

      - grant {
          - id          = "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783" -> null
          - permissions = [
              - "FULL_CONTROL",
            ] -> null
          - type        = "CanonicalUser" -> null
            # (1 unchanged attribute hidden)
        }

      - server_side_encryption_configuration {
          - rule {
              - bucket_key_enabled = false -> null

              - apply_server_side_encryption_by_default {
                  - sse_algorithm     = "AES256" -> null
                    # (1 unchanged attribute hidden)
                }
            }
        }

      - versioning {
          - enabled    = false -> null
          - mfa_delete = false -> null
        }
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.storage.aws_s3_bucket.log_bucket: Destroying... [id=bluedragon-log-bucket-qt386gvs]
module.storage.aws_s3_bucket.log_bucket: Destruction complete after 1s
random_string.suffix: Destroying... [id=qt386gvs]
random_string.suffix: Destruction complete after 0s

Destroy complete! Resources: 2 destroyed.
(py3) tim@Tims-MBP single_instance % 

(py3) tim@Tims-MBP single_instance % aws s3 ls
2025-03-14 13:13:46 bluedragon-employer-prod
2025-03-14 12:58:11 bluedragon-employer-prod-logs
(py3) tim@Tims-MBP single_instance % 
(py3) tim@Tims-MBP single_instance % aws s3 ls s3://bluedragon-employer-prod --recursive
2025-01-23 12:57:52        180 ./terraform.tfstate
2025-03-27 08:52:57        183 single_instance_terraform.tfstate
(py3) tim@Tims-MBP single_instance % aws s3 rm s3://bluedragon-employer-prod --recursive
delete: s3://bluedragon-employer-prod/single_instance_terraform.tfstate
delete: s3://bluedragon-employer-prod/./terraform.tfstate
(py3) tim@Tims-MBP single_instance % aws s3api delete-objects --bucket bluedragon-employer-prod --delete "$(aws s3api list-object-versions --bucket bluedragon-employer-prod --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
{
    "Deleted": [
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "6ODOLuqiX6lEMQyfZvWfUsSvAyYS1IfY"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "A2nDx9q5AfhAoYjxlia_DR2fXMm2SWN4"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "Wg7ibUiYak_BclIrXNMnUniN4o3qWNLI"
        },
        {
            "Key": "./terraform.tfstate",
            "VersionId": "ViK2bbq8HDJuwPjdQqyoJKiNwcq1QRNP"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "6SzeGJAy7ZQB8pYd0bGLD.KzPMoGA0z."
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "18yvppqaHHwmsUUsFLd9FRAidnHp5A.W"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "JYzkvrw3oyucg4Vn3DXcE7VvLYRcpH2R"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "Ba8H_k.wpnd_u7RH9pdYFo4yRAf1q_SU"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "i9LZ6ZK5uADCoH624eBoHWz23o1E6DkK"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "9krJJB8CybikGKoj7udrMK_v_Oa5RJ0S"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "3q.Vq_03_N7dmkSsB7W6B_DiaF.wZ8sL"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "lzGbIGAMgQvhGrYqV1lnM8US4NOi1d48"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "E0irma8ZdMXv2yiYKj9TbRVaXw6gXorL"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "Vnseshs2m6JR.mrbic5gTwHhrvOmf9hy"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "KZacQVdvVMrq.Wnb6jm9vTM5qrZ6cblv"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "AmUGUMs318AHnPhM4sLZDQoHWF8Z_4.O"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "Z9hwhcgKTSYMBvaqiiMr54OTHPW350qP"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "3KhW0UN6X.ymYYuJdIMlqEoiBiEVhtnt"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "ZGBAARDFGpLlJISmwktzSDRWd1JFHQ42"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "I7LUPEM3kATQLHQPmeHNjQcyh94hqfVp"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "l0XsaCGSGozTMu7tGybdDBZv2BFhhgB4"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "3pMB8qaK2FbpHbe0YQ_Le_vhp6bG40Sq"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "6Eed6EG_23uGWKIre7w4TulLydf5We.V"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "DiL.KrcQzjzylYNynLUpXNLY1eZ9iMI8"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "ZWMkMEq2C6vxtIvdNnuwNBCkcS8XCxNA"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "bp0VvDcCdId5Lo5CF92h9esfnpeDe2BB"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "l8iaihcuf55oPWYBqnlBnrg5_xhjWIPT"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "CAmZUwmkusGEYLbUS9XyifN.ppz295D7"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "gs1U6ZBxegKXiV0U6EIL.jv7uCfzj_gK"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "GpfxXDZ5y4DXbXCUd..VpGfMzAh62_5s"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "nSdJyElTOKcKFFdEN6xrjrgamPYWEC55"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "M2Yqqlj1ldRyUI3FyeNKAnEoWHHFJaDE"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "ZI8cIZtwOBX6cn633XZjfgvD.go2rA3u"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "OZkVFrON1POGbxRmzOYfau6Hmfxu_c2y"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "S1BPfCIIkoAGgXQppABm5q270KbRPNKc"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "EAaAWbBusMEruaO24B3Rr7ZDBskwAySp"
        },
        {
            "Key": "./terraform.tfstate",
            "VersionId": "L5Pglspyp7aRqo_bqYXphLQ7MTcfcs7V"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "5ZUOlwRmil4Ma4F7amRnUWGCrShP.r6Y"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "kddGtS3TFkSJz62Aby0fuVqVDKLVeJjZ"
        },
etc

(py3) tim@Tims-MBP single_instance % aws s3 ls                                          
2025-03-14 13:13:46 bluedragon-employer-prod
2025-03-14 12:58:11 bluedragon-employer-prod-logs
(py3) tim@Tims-MBP single_instance % aws s3 rm s3://bluedragon-employer-prod --recursive
(py3) tim@Tims-MBP single_instance % aws s3api delete-objects --bucket bluedragon-employer-prod --delete "$(aws s3api list-object-versions --bucket bluedragon-employer-prod --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

Parameter validation failed:
Invalid type for parameter Delete.Objects, value: None, type: <class 'NoneType'>, valid types: <class 'list'>, <class 'tuple'>
(py3) tim@Tims-MBP single_instance % aws s3 ls                                          
2025-03-14 13:13:46 bluedragon-employer-prod
2025-03-14 12:58:11 bluedragon-employer-prod-logs

(py3) tim@Tims-MBP single_instance % aws s3 ls s3://bluedragon-employer-prod --recursive
(py3) tim@Tims-MBP single_instance % 

(py3) tim@Tims-MBP single_instance % aws s3 ls s3://bluedragon-employer-prod --recursive
(py3) tim@Tims-MBP single_instance % aws s3 rm s3://bluedragon-employer-prod-logs --recursive
(py3) tim@Tims-MBP single_instance % aws s3 rm s3://bluedragon-employer-prod --recursive 
(py3) tim@Tims-MBP single_instance % 

(py3) tim@Tims-MBP single_instance % aws s3 ls
2025-03-14 13:13:46 bluedragon-employer-prod
2025-03-14 12:58:11 bluedragon-employer-prod-logs

(py3) tim@Tims-MBP single_instance % terraform state list
Failed to load state: state data in S3 does not have the expected content.

The checksum calculated for the state stored in S3 does not match the checksum
stored in DynamoDB.

Bucket: bluedragon-employer-prod
Key:    single_instance_terraform.tfstate
Calculated checksum: 
Stored checksum:     502a3cd7cb541d411b17406b34c709aa

This may be caused by unusually long delays in S3 processing a previous state
update. Please wait for a minute or two and try again.

If this problem persists, and neither S3 nor DynamoDB are experiencing an
outage, you may need to manually verify the remote state and remove the Digest
value stored in the DynamoDB table

(py3) tim@Tims-MBP single_instance % aws s3 rb s3://bluedragon-employer-prod-logs --force
remove_bucket: bluedragon-employer-prod-logs

(py3) tim@Tims-MBP single_instance % aws s3 ls                                           
2025-03-14 13:13:46 bluedragon-employer-prod
(py3) tim@Tims-MBP single_instance % aws s3 rb s3://bluedragon-employer-prod --force     
remove_bucket failed: s3://bluedragon-employer-prod An error occurred (BucketNotEmpty) when calling the DeleteBucket operation: The bucket you tried to delete is not empty. You must delete all versions in the bucket.

(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-employer-prod
{
    "DeleteMarkers": [
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "./terraform.tfstate",
            "VersionId": "1P2p.1vSbWvzysa7YVjqok.Pd6E7oJBV",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        },
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "pAphzdc2mj5a_ruc9JHWv4EgAewAalh_",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        }
    ],
    "RequestCharged": null,
    "Prefix": ""
}

(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-employer-prod
{
    "DeleteMarkers": [
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "./terraform.tfstate",
            "VersionId": "1P2p.1vSbWvzysa7YVjqok.Pd6E7oJBV",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        },
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "pAphzdc2mj5a_ruc9JHWv4EgAewAalh_",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        }
    ],
    "RequestCharged": null,
    "Prefix": ""
}
(py3) tim@Tims-MBP single_instance % aws s3api delete-objects --bucket bluedragon-employer-prod --delete "$(aws s3api list-object-versions --bucket bluedragon-employer-prod --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

Parameter validation failed:
Invalid type for parameter Delete.Objects, value: None, type: <class 'NoneType'>, valid types: <class 'list'>, <class 'tuple'>
(py3) tim@Tims-MBP single_instance % aws s3 rb s3://bluedragon-employer-prod --force                 

remove_bucket failed: s3://bluedragon-employer-prod An error occurred (BucketNotEmpty) when calling the DeleteBucket operation: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
(py3) tim@Tims-MBP single_instance % 
(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-employer-prod
{
    "DeleteMarkers": [
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "./terraform.tfstate",
            "VersionId": "1P2p.1vSbWvzysa7YVjqok.Pd6E7oJBV",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        },
        {
            "Owner": {
                "DisplayName": "kerstarsoc",
                "ID": "d1cac264defe43a71aaf5902368dbc9bdf76433489b0071b47ff95ac321cb783"
            },
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "pAphzdc2mj5a_ruc9JHWv4EgAewAalh_",
            "IsLatest": true,
            "LastModified": "2025-03-27T15:55:36+00:00"
        }
    ],
    "RequestCharged": null,
    "Prefix": ""
}

(py3) tim@Tims-MBP single_instance % aws s3api delete-objects --bucket bluedragon-employer-prod --delete "$(aws s3api list-object-versions --bucket bluedragon-employer-prod --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
{
    "Deleted": [
        {
            "Key": "./terraform.tfstate",
            "VersionId": "1P2p.1vSbWvzysa7YVjqok.Pd6E7oJBV",
            "DeleteMarker": true,
            "DeleteMarkerVersionId": "1P2p.1vSbWvzysa7YVjqok.Pd6E7oJBV"
        },
        {
            "Key": "single_instance_terraform.tfstate",
            "VersionId": "pAphzdc2mj5a_ruc9JHWv4EgAewAalh_",
            "DeleteMarker": true,
            "DeleteMarkerVersionId": "pAphzdc2mj5a_ruc9JHWv4EgAewAalh_"
        }
    ]
}
(py3) tim@Tims-MBP single_instance % aws s3api list-object-versions --bucket bluedragon-employer-prod
{
    "RequestCharged": null,
    "Prefix": ""
}
(py3) tim@Tims-MBP single_instance % aws s3 rb s3://bluedragon-employer-prod --force                 
remove_bucket: bluedragon-employer-prod

(py3) tim@Tims-MBP single_instance % cd ../tfstate
(py3) tim@Tims-MBP tfstate % terraform init
Initializing the backend...
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v4.67.0...
- Installed hashicorp/aws v4.67.0 (signed by HashiCorp)
Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
(py3) tim@Tims-MBP tfstate % vi create_s3_bucket.tf 
(py3) tim@Tims-MBP tfstate % terraform destroy
aws_kms_key.dynamodb_key: Refreshing state... [id=d16e2125-c3d9-4887-815b-ca83f400ed9d]
aws_kms_key.state_bucket_key: Refreshing state... [id=ba900911-142d-4b8c-b1bc-28e4fdf9a6b0]
aws_kms_key.log_bucket_key: Refreshing state... [id=1798b629-4927-424a-9cec-a432a0714b6d]
aws_s3_bucket.state_log_bucket: Refreshing state... [id=bluedragon-employer-prod-logs]
aws_s3_bucket.state_bucket: Refreshing state... [id=bluedragon-employer-prod]
aws_dynamodb_table.terraform_locks: Refreshing state... [id=terraform-locks]
aws_s3_bucket_public_access_block.state_log_bucket: Refreshing state... [id=bluedragon-employer-prod-logs]
aws_s3_bucket_server_side_encryption_configuration.state_log_bucket: Refreshing state... [id=bluedragon-employer-prod-logs]
aws_s3_bucket_logging.state_bucket_logging: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_ownership_controls.ownership: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_server_side_encryption_configuration.state_bucket_encryption: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_public_access_block.block_public_access: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_versioning.state_bucket_versioning: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_lifecycle_configuration.state_bucket_lifecycle: Refreshing state... [id=bluedragon-employer-prod]
aws_s3_bucket_acl.state_bucket_acl: Refreshing state... [id=bluedragon-employer-prod,private]

