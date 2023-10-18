
nldas_feature_dataset_prop <- function(ds, hydrocode,bundle,ftype,model_version_code,dataset, scen_run = 0) {
# read in a model container
# scen_run: stash this data as a model scenario?  This is new.
lseg_feature <- RomFeature$new(
  ds, list(
    ftype = ftype,
    bundle = bundle,
    hydrocode = hydrocode
  ),
  TRUE
)
if (!(lseg_feature$hydroid > 0)) {
  message(paste("Could not find", hydrocode))
  next
}
base_model <- RomProperty$new(
  ds, list(
    featureid = lseg_feature$hydroid,
    propcode = model_version_code,
    varkey = 'om_model_element',
    entity_type = 'dh_feature'
  ),
  TRUE
)
if (is.na(base_model$pid)) {
  message(paste("Could not find mode for", hydrocode, ", creating."))
  base_model$propname <- paste(lseg_feature$name, model_version_code)
  base_model$save(TRUE)
}

if (!(scen_run == 1)) {
  nldas_datasets <- RomProperty$new(
    ds, list(
      featureid = base_model$pid,
      propname = 'nldas_datasets',
      entity_type = 'dh_properties'
    ),
    TRUE
  )
  if (is.na(nldas_datasets$pid)) {
    message(paste("Could not find NLDAS datasets for", hydrocode, ", creating."))
    nldas_datasets$save(TRUE)
  }


  nldas_data <- RomProperty$new(
    ds, list(
      featureid = nldas_datasets$pid,
      propname = dataset,
      entity_type = 'dh_properties'
    ),
    TRUE
  )
} else {
  # attach as model scenario
  message("Using new method to store data as a scenario")
  nldas_data <- RomProperty$new(
    ds, list(
      featureid = base_model$pid,
      propname = dataset,
      entity_type = 'dh_properties',
      varkey = 'om_scenario'
    ),
    TRUE
  )
}

if (is.na(nldas_data$pid)) {
  message(paste("Could not find NLDAS", dataset, ", creating."))
  nldas_data$save(TRUE)
}

return(nldas_data)
}
