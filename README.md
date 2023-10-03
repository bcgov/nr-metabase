![Lifecycle:Experimental](https://img.shields.io/badge/Lifecycle-Experimental-339999)
# NR Metabase
A Helm Chart to deploy a Metabase Instance with Encrypted Listener Support to do reporting against Oracle DB.

## How to Deploy to OpenShift using the OpenShift Console.
1. Login to OpenShift GUI.
2. switch to Developer view.
3. Click on Helm
4. Click on Repository on the right hand side.![img.png](.graphics/helm_create_repository.png)
5. Give a name, for example: `metabase`
6. Give the URL: `https://bcgov.github.io/nr-metabase/`, click on Create.
7. Go to Helm on the left hand menu again and click on `Install a Helm Chart from the developer catalog`
8. you should see `metabase` in the list, click on it.![img.png](.graphics/metabase_logo.png)
9. Click on the Nr Metabase and then install Helm Chart button.
10. Select Chart version, which is same as metabase version, for example: `0.47.1` and click on Install button.
