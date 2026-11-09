@AbapCatalog.sqlViewName: 'ZRSPAC112STOCK'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data element for product stock'
@Metadata.ignorePropagatedAnnotations: true
define root view ZR_SPAC112_STOCK as select from zspac112_stock
{
  key warehouse_id as warehouse_id,
  key product_id as product_id,
  amount as Amount
}
