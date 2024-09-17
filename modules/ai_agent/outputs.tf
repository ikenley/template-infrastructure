#------------------------------------------------------------------------------
# replicate regional outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# regional.tf
#------------------------------------------------------------------------------

output "agent_id" {
  value = module.regional_primary.agent_id
}

output "agent_alias_current_id" {
  value = module.regional_primary.agent_alias_current_id
}
