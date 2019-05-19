<#
Managed Instance are not supported in Visual Studio Enterprise subscription.
If you are using Pay-as-you-go subscription, do check the managed instance cost
#>
param(
[string]$ResourceGroup="Packt-1",
[string]$Location="centralus",
[string]$vNet="PackvNet-$(Get-Random)",
[string]$misubnet="PackSubnet-$(Get-Random)",
[string]$miname="Packt-$(Get-Random)",
[string]$miadmin="miadmin",
[string]$miadminpassword,
[string]$miedition="General Purpose",
[string]$mivcores=8,
[string]$mistorage=32,
[string]$migeneration = "Gen4",
[string]$milicense="LicenseIncluded",
[string]$subscriptionid="f0193880-5aca-4fbd-adf4-953954e4fdd7"
)

# login to azure

$Account = Connect-AzAccount

if([string]::IsNullOrEmpty($subscriptionid))
{
   $subscriptionid=$Account.Context.Subscription.Id
}

Set-AzContext $subscriptionid

# Check if resource group exists
# An error is returned and stored in notexists variable if resource group exists
Get-AzResourceGroup -Name $ResourceGroup -Location $location -ErrorVariable notexists -ErrorAction SilentlyContinue

#Provision Azure Resource Group
if(![string]::IsNullOrEmpty($notexists))
{

Write-Host "Provisioning Azure Resource Group $ResourceGroup" -ForegroundColor Green
$_ResourceGroup = @{
  Name = $ResourceGroup;
  Location = $Location;
  }
New-AzResourceGroup @_ResourceGroup;
}
else
{

Write-Host $notexists -ForegroundColor Yellow
}


Write-Host "Provisioning Azure Virtual Network $vNet" -ForegroundColor Green
$obvnet = New-AzVirtualNetwork -Name $vNet -ResourceGroupName $ResourceGroup -Location $Location -AddressPrefix "10.0.0.0/16"

Write-Host "Provisioning Managed instance subnet $misubnet" -ForegroundColor Green

$obmisubnet = Add-AzVirtualNetworkSubnetConfig -Name $misubnet -VirtualNetwork $obvnet -AddressPrefix "10.0.0.0/24"
$misubnetid = $obmisubnet.Id
$_nsg = "mi-nsg"
$_rt = "mi-rt"

Write-Host "Provisioning Network Security Group" -ForegroundColor Green
$nsg = New-AzNetworkSecurityGroup -Name $_nsg -ResourceGroupName $ResourceGroup -Location $Location -Force

<#
Routing table is required for a managed instance to connect with 
Azure Management Service. 
#>
Write-Host "Provisioning Routing table" -ForegroundColor Green
$routetable = New-AzRouteTable -Name $_rt -ResourceGroupName $ResourceGroup -Location $Location -Force

#Assign network security group to managed instance subnet
Set-AzVirtualNetworkSubnetConfig `
-VirtualNetwork $obvnet -Name $misubnet `
-AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg `
-RouteTable $routetable | Set-AzVirtualNetwork

#Configure network rules in network security group
Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $_nsg `
 | Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 9000,9003,1438,1440,1452 `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix "10.0.0.0/24" `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 300 `
                      -Name "allow_health_probe_inbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix AzureLoadBalancer `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 1000 `
                      -Name "allow_tds_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 1433 `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 1100 `
                      -Name "allow_redirect_inbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix VirtualNetwork `
                      -DestinationPortRange 11000-11999 `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_inbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Inbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 100 `
                      -Name "allow_management_outbound" `
                      -Access Allow `
                      -Protocol Tcp `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange 80,443,12000 `
                      -DestinationAddressPrefix * `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 200 `
                      -Name "allow_misubnet_outbound" `
                      -Access Allow `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix "10.0.0.0/24" `
| Add-AzNetworkSecurityRuleConfig `
                      -Priority 4096 `
                      -Name "deny_all_outbound" `
                      -Access Deny `
                      -Protocol * `
                      -Direction Outbound `
                      -SourcePortRange * `
                      -SourceAddressPrefix * `
                      -DestinationPortRange * `
                      -DestinationAddressPrefix * `
| Set-AzNetworkSecurityGroup                    

#Set routing table configuration
Get-AzRouteTable `
    -ResourceGroupName $ResourceGroup `
    -Name $_rt `
    | Add-AzRouteConfig `
    -Name "ToManagedInstanceManagementService" `
    -AddressPrefix 0.0.0.0/0 `
    -NextHopType Internet `
    | Add-AzRouteConfig `
    -Name "ToLocalClusterNode" `
    -AddressPrefix "10.0.0.0/24" `
    -NextHopType VnetLocal `
    | Set-AzRouteTable


# Provision managed instance
 ConvertTo-SecureString 
 $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $miadmin, (ConvertTo-SecureString -String $miadminpassword -AsPlainText -Force)

New-AzSqlInstance -Name $miname -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $misubnetid `
                      -AdministratorCredential $creds `
                      -StorageSizeInGB $mistorage -VCore $mivcores -Edition $miedition
                      -ComputeGeneration $migeneration -LicenseType $milicense


<#
Clean-Up : Remove managed instance
Remove-AzSqlInstance -Name $miadmin -ResourceGroupName $ResourceGroup -Force

#>