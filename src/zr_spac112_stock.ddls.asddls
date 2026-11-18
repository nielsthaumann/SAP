@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product stock'
define root view entity ZR_SPAC112_STOCK
  as select from zspac112_stock as stock
  association [0..1] to zspac112_product as _Product
    on $projection.product_id = _Product.product_id
  association [0..1] to zspac112_whouse as _Warehouse
    on $projection.warehouse_id = _Warehouse.warehouse_id
{
  key stock.warehouse_id as warehouse_id,
  key stock.product_id   as product_id,
      stock.amount       as Amount,

      _Product,
      _Warehouse
}
