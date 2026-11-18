@AbapCatalog.sqlViewName: 'ZRSPAC112STOCKV'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View'
@Metadata.allowExtensions: true
define root view ZC_SPAC112_STOCK as select from ZR_SPAC112_STOCK
{
  key warehouse_id,
  key product_id,
      Amount,
      product_name,
      product_description,
      warehouse_name,
      warehouse_address,
      warehouse_city,
      warehouse_zipcode
}
