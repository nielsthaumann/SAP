@AbapCatalog.sqlViewName: 'ZRSPAC112STOCKV'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View'
@Metadata.ignorePropagatedAnnotations: true
define root view ZC_SPAC112_STOCK as select from ZR_SPAC112_STOCK
{
  key warehouse_id,
  key product_id,
  Amount
}
