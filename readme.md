## Helm Template

[參考文件](https://cloud.google.com/artifact-registry/docs/helm/store-helm-charts)

### Gitlab-ci.yml 檔案內使用的 docker image 版本是

[gcloud-kubectl-helm](https://hub.docker.com/r/azman0101/gcloud-kubectl-helm/tags)

建立 Helm Template 的指令

```
helm create <helm 的名稱>
```

執行 helm chart 的指令

```
helm install <名稱> <helm chart 路徑>
```

檢查目前 releases 的服務

```
helm list
```

刪除已經 release 的 chart

```
helm delete <release 名稱>
或
helm uninstall <release 名稱>
```

將 helm chart 推到 GCP 的 Artifact Registry 流程

1. 打包 helm chart

```
helm package <helm chart 資料夾名稱>/
```

2. GCP repository 授權

```
gcloud auth print-access-token | helm registry login -u oauth2accesstoken --password-stdin https://<artifact registry region>-docker.pkg.dev
```

3. 將 Helm Chart .tgz 檔案推到 Artifact Registry 上

```
helm push <helm chart 名稱>.tgz oci://<artifact registry region>-docker.pkg.dev/<GCP_PROJECT_ID>/<artifact registry repo 名稱>
```
