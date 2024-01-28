DIR=$(pwd)
PROJECTDIR=$(basename $(pwd))

terraform_working_dir="terraform-azure"
az_resource_group_name=$PROJECTDIR"_rg"
az_static_web_app_name="$PROJECTDIR"

service_principal_name=$PROJECTDIR"_sp"


acc_info=$(az account list -o json)
sub_id=$(echo "$acc_info" | jq -r '.[0].id')
ARM_SUBSCRIPTION_ID=$sub_id
az account set --subscription $sub_id

echo "Creating service principal..."
sp_info=$(az ad sp create-for-rbac --name "$service_principal_name" --role="Contributor" --scopes="/subscriptions/$sub_id" -o json)
ARM_CLIENT_ID=$(echo "$sp_info" | jq -r '.appId')
ARM_CLIENT_SECRET=$(echo "$sp_info" | jq -r '.password')
ARM_TENANT_ID=$(echo "$sp_info" | jq -r '.tenant')
echo "Service principal created for $sub_name:"