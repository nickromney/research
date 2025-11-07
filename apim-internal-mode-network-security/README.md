# Azure APIM Internal Mode & Network Security

Research project focused on securing Azure API Management at the infrastructure level by deploying in "Internal" mode and understanding network security patterns.

## Overview

This research explores how to deploy Azure APIM in Internal mode, where the API Gateway is only accessible from within a Virtual Network (VNet). This is critical for organizations that need to expose APIs only to internal services or through controlled ingress points.

## Key Concepts

### APIM Network Modes

Azure APIM supports three network connectivity modes:

1. **External** (Default): Both developer portal and API gateway are accessible from the public internet
2. **Internal**: Developer portal and API gateway are only accessible from within the VNet
3. **None**: No VNet integration

### Internal Mode Architecture

In Internal mode:
- APIM is deployed with a private IP address within your VNet
- All APIM endpoints (gateway, portal, management, git) are only accessible via VNet
- Requires Azure VNet and subnet with sufficient address space
- Supports integration with Application Gateway, Azure Firewall, or other reverse proxies

## Research Goals

- [ ] Deploy APIM in Internal mode on Developer tier (if supported) or understand limitations
- [ ] Configure VNet integration with proper subnet sizing
- [ ] Set up DNS for internal APIM endpoints
- [ ] Test connectivity from within the VNet
- [ ] Document the differences between Internal and External modes
- [ ] Explore integration patterns with Azure Application Gateway for external access
- [ ] Understand NSG (Network Security Group) requirements
- [ ] Test private endpoint scenarios vs Internal mode

## Key Questions to Answer

1. **Does Developer tier support Internal mode?**
   - If yes, what are the limitations vs Premium tier?
   - If no, what's the most cost-effective alternative?

2. **What subnet size is required?**
   - Minimum CIDR block size
   - IP address allocation patterns
   - Planning for scale

3. **How to provide external access?**
   - Azure Application Gateway integration
   - Azure Front Door integration
   - Custom reverse proxy solutions
   - Cost implications of each approach

4. **DNS Configuration**
   - Custom domain setup for Internal mode
   - DNS zones and resolution
   - Certificate management for custom domains

5. **Security Groups & Firewall Rules**
   - Required NSG rules for APIM Internal mode
   - Service tags and security rules
   - Integration with Azure Firewall

## Deployment Approaches

### Option 1: Developer Tier Testing (if supported)
```bash
# Create resource group
az group create --name rg-apim-internal-dev --location eastus

# Create VNet
az network vnet create \
  --name vnet-apim \
  --resource-group rg-apim-internal-dev \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-apim \
  --subnet-prefix 10.0.1.0/24

# Create APIM in Internal mode (check tier support)
az apim create \
  --name apim-internal-dev \
  --resource-group rg-apim-internal-dev \
  --publisher-email your@email.com \
  --publisher-name "Your Name" \
  --sku-name Developer \
  --virtual-network Internal \
  --subnet-resource-id /subscriptions/{sub-id}/resourceGroups/rg-apim-internal-dev/providers/Microsoft.Network/virtualNetworks/vnet-apim/subnets/subnet-apim
```

### Option 2: Consumption Tier with VNet Integration
If Developer tier doesn't support Internal mode, explore Consumption tier with VNet integration:
- Lower cost model (pay per execution)
- Limited VNet integration capabilities
- Suitable for learning concepts

### Option 3: Pluralsight Sandbox
Use 4-hour Pluralsight sandbox to deploy Premium/Standard tier for testing:
- Deploy in Internal mode
- Test all features
- Document findings before sandbox expires
- Take screenshots and export configurations

## Network Security Best Practices

### 1. Subnet Planning
- Use dedicated subnet for APIM (do not share with other services)
- Minimum /27 subnet recommended for production
- /29 may work for development/testing
- Plan for future scale

### 2. NSG Configuration
Required inbound rules:
- Allow Azure Load Balancer health probes
- Allow Azure infrastructure communication
- Allow custom application ports if needed

Required outbound rules:
- Azure Storage for APIM dependencies
- Azure SQL for APIM database (if applicable)
- Azure Active Directory for authentication
- Backend services
- Azure Monitor for diagnostics

### 3. Service Endpoints vs Private Endpoints
- **Service Endpoints**: Free, VNet-level access to Azure services
- **Private Endpoints**: Dedicated private IP, subnet-level isolation, additional cost

### 4. DNS Considerations
- Configure private DNS zones for internal resolution
- Use Azure Private DNS or custom DNS servers
- Ensure proper name resolution for all APIM endpoints:
  - `{apim-name}.azure-api.net` (gateway)
  - `{apim-name}.portal.azure-api.net` (developer portal)
  - `{apim-name}.management.azure-api.net` (management API)

## Testing Checklist

- [ ] Deploy APIM instance in Internal mode
- [ ] Verify APIM is not accessible from public internet
- [ ] Deploy test VM in same VNet to verify internal access
- [ ] Configure custom domain with certificate
- [ ] Set up NSG rules and verify connectivity
- [ ] Test API calls from within VNet
- [ ] Test developer portal access from VNet
- [ ] Document DNS configuration steps
- [ ] Test backend connectivity to Azure Functions
- [ ] Test backend connectivity to AKS
- [ ] Measure deployment time and costs

## Cost Analysis

### Developer Tier Internal Mode
- Monthly cost: ~$50/month (if supported)
- VNet: Free
- NSG: Free
- Private DNS Zone: ~$0.50/month

### Alternative: Standard v2 with Private Endpoint
- Monthly cost: ~$800/month (Standard v2 base)
- Private Endpoint: ~$7.30/month
- **Too expensive for learning purposes**

### Alternative: Consumption Tier
- Monthly cost: Pay per execution
- First 1 million executions: $3.50
- Good for learning, but limited features

## Resources and References

### Official Documentation
- [Azure APIM Network Configuration](https://docs.microsoft.com/azure/api-management/api-management-using-with-internal-vnet)
- [Connect to Internal VNet using APIM](https://docs.microsoft.com/azure/api-management/api-management-using-with-internal-vnet)
- [APIM Networking FAQs](https://docs.microsoft.com/azure/api-management/api-management-faq#networking)

### Azure Samples
- [Azure-Samples/Apim-Samples](https://github.com/Azure-Samples/Apim-Samples)
- Note: Private endpoint sample uses expensive Standard v2 tier

### Network Design Patterns
- [Hub-Spoke Network Topology with APIM](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [APIM with Application Gateway](https://docs.microsoft.com/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway)

### Community Resources
- Stack Overflow APIM tag
- Azure APIM GitHub discussions
- Microsoft Tech Community

## Findings and Notes

### [Date: TBD] Initial Investigation
_Document findings here as you explore_

### [Date: TBD] Deployment Attempts
_Document deployment attempts, successes, and failures_

### [Date: TBD] Cost Optimization Discoveries
_Document any cost-saving patterns discovered_

## Next Steps

1. Verify Developer tier capabilities for Internal mode
2. Plan VNet architecture for testing
3. Deploy first Internal APIM instance
4. Document step-by-step deployment process
5. Create reusable ARM/Bicep templates
6. Test connectivity patterns
7. Document lessons learned

## Related Research Projects

- [APIM Policy Security Best Practices](../apim-policy-security/)
- [APIM Multi-tenant Access Segmentation](../apim-multitenant-access/)
- [APIM Developer Tier Cost-Effective Patterns](../apim-developer-tier-patterns/)
- [APIM Backend Integration Patterns](../apim-backend-integration/)

## Status

**Status**: 🟡 Not Started
**Last Updated**: 2025-11-07
**Estimated Effort**: 8-12 hours
